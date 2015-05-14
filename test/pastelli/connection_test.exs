defmodule Pastelli.ConnectionTest do
  use ExUnit.Case
  require Logger

  # this is more or less
  # https://github.com/elixir-lang/plug/blob/master/test/plug/adapters/cowboy/conn_test.exs

  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, []) do
    function = String.to_atom List.first(conn.path_info) || "root"
    apply __MODULE__, function, [conn]
  rescue
    exception ->
      # receive do
      #   {:plug_conn, :sent} ->
      #     :erlang.raise(:error, exception, :erlang.get_stacktrace)
      # after
      #   0 ->
      send_resp(conn, 500, Exception.message(exception) <> "\n" <>
        Exception.format_stacktrace(System.stacktrace))
  end

  setup_all do
    {:ok, pid} = Pastelli.http __MODULE__, [], port: 8001
    Process.unlink pid
    on_exit fn ->
      :ok = Pastelli.shutdown __MODULE__.HTTP
    end
    :ok
  end

  defp request(verb, path, headers \\ [], body \\ "") do
    {:ok, status, headers, client} =
      :hackney.request(verb, "http://127.0.0.1:8001" <> path, headers, body, [])
    {:ok, body} = :hackney.body(client)
    :hackney.close(client)
    {status, headers, body}
  end

  def send_200(conn) do
    assert conn.state == :unset
    assert conn.resp_body == nil
    conn = send_resp(conn, 200, "OK")
    assert conn.state == :sent

    # behaviour differs from cowboy adapter here
    assert conn.resp_body == "OK"

    conn
  end

  def send_500(conn) do
    conn
    |> delete_resp_header("cache-control")
    |> put_resp_header("x-sample", "value")
    |> send_resp(500, ["ERR", ["OR"]])
  end

  test "sends a response with status, headers and body" do
    assert {200, headers, "OK"} = request :get, "/send_200"
    assert List.keyfind(headers, "cache-control", 0) ==
      {"cache-control", "max-age=0, private, must-revalidate"}
    assert {500, headers, "ERROR"} = request :get, "/send_500"
    assert List.keyfind(headers, "cache-control", 0) == nil
    assert List.keyfind(headers, "x-sample", 0) ==
           {"x-sample", "value"}
  end

  def send_chunked(conn) do
    conn = send_chunked(conn, 200)
    assert conn.state == :chunked
    conn = assign(conn, :init_chunk, "data: HANDSHAKE\n\n")

    spawn_link fn()->
      :timer.sleep 200
      {:ok, conn} = chunk(conn, "data: HELLO\n\n")
      :timer.sleep 100
      {:ok, conn} = chunk(conn, "data: WORLD\n\n")
      {handler, req} = conn.adapter
      handler.close_chunk(req)
    end

    conn
  end

  test "I can send an initial chunk, then 2 deferred chunks and then I can close
        the connection" do
    {:ok, status, headers, client} =
      :hackney.request(:get, "http://127.0.0.1:8001/send_chunked", [], "", [])
    :timer.sleep 400
    {:ok, body} = :hackney.body(client)
    assert body == "data: HANDSHAKE\n\ndata: HELLO\n\ndata: WORLD\n\n"
  end


  defmodule SideEffect do
    use GenServer

    def start_link(test_pid) do
      GenServer.start_link __MODULE__,
        %{test_pid: test_pid},
        name: __MODULE__
    end

    def register(conn) do
      GenServer.call __MODULE__, {:register, conn}
    end

    def handle_call {:register, conn}, _from, state do
      pid = spawn fn ->
        :timer.sleep 200
        {:ok, _conn} = Plug.Conn.chunk(conn, "data: please don't cl\n\n")
        :timer.sleep :infinity
      end
      Process.monitor pid
      {:reply, pid, Map.put(state, :linked_pid, pid)}
    end

    def handle_info {:DOWN, _ref, :process, pid, :shutdown}, state do
      match_pid = state.linked_pid
      ^match_pid = pid
      send state.test_pid, :conn_process_was_shut_down
      {:noreply, state}
    end
  end

  def send_chunky(conn) do
    conn = send_chunked(conn, 200) |> assign(:init_chunk, "data: HANDSHAKE\n\n")
    SideEffect.register(conn) |> Process.link()
    conn
  end

  test "I can send chunks, but client closes the connection,
        my connection pid gets killed!" do
    {:ok, _pid} = SideEffect.start_link(self)
    spawn_link fn()->
      {:ok, _status, _headers, client} =
        :hackney.request(:get, "http://127.0.0.1:8001/send_chunky", [], "", [])
      :timer.sleep 300
      assert {:ok, "data: HANDSHAKE\n\n"} == :hackney.stream_body(client)
      assert {:ok, "data: please don't cl\n\n"} == :hackney.stream_body(client)
      :timer.sleep 200
      :hackney.close(client)
    end
    assert_receive(:conn_process_was_shut_down, 800)
  end
end
