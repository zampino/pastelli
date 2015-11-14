defmodule Pastelli.HandlerTest do
  use ExUnit.Case
  import Mock

  require Record
  Record.defrecord :req, Record.extract(:req, from: "deps/elli/include/elli.hrl")

  def build_req(keyword\\[]) do
    base_headers = [{"Host", "somehost"}, {"X-Forwarded-For", "127.0.0.1"}]
    req(headers: keyword ++ base_headers, raw_path: "some/nice/path")
  end

  test "init to handover flow" do
    request = build_req [{"Upgrade", "websocket"}]
    init_return = Pastelli.Handler.init(request, {:plug, :options})
    assert init_return == {:ok, :handover}
  end

  test "init to standard flow" do
    init_return = Pastelli.Handler.init(build_req([]), {:plug, :options})
    assert init_return == {:ok, :standard}
  end

  defmodule UpgradePlug do
    import Plug.Conn
    def call(conn, :options) do
      put_private(conn, :upgrade, {:websocket, :ws_handler})
    end
  end

  test_with_mock "handle to upgrade", :elli_websocket,
    [upgrade: fn(_req, options) -> :ok end] do
    request = build_req
    conn = Pastelli.Connection.build_from(request) |> UpgradePlug.call(:options)

    assert Pastelli.Handler.handle(request, {UpgradePlug, :options})
      == {:close, ''}

    assert called :elli_websocket.upgrade(request,
      handler: :ws_handler, handler_opts: [conn: conn])
  end

  defmodule FilePlug do
    import Plug.Conn
    def call(conn, :options) do
      send_file(conn, 200, "some/file/path")
    end
  end

  test "handle to file" do
    assert Pastelli.Handler.handle(build_req, {FilePlug, :options})
      == {200, [
        {"Connection", "close"},
        {"cache-control", "max-age=0, private, must-revalidate"}
        ], {:file, "some/file/path"}}
  end

  defmodule ChunkPlug do
    import Plug.Conn
    def call(conn, :options) do
      send_chunked(conn, 200) |> put_private(:init_chunk, "HALLO")
    end
  end

  test "handle to chunk, with initial chunk" do
    assert Pastelli.Handler.handle(build_req, {ChunkPlug, :options})
      == {:chunk, [
        {"cache-control", "max-age=0, private, must-revalidate"}
        ], "HALLO"}
  end

  defmodule SendPlug do
    import Plug.Conn
    def call(conn, :options) do
      send_resp(conn, 201, "BODY")
    end
  end

  test "handle to sent" do
    assert Pastelli.Handler.handle(build_req, {SendPlug, :options})
      == {201, [
        {"cache-control", "max-age=0, private, must-revalidate"}
        ],
        "BODY"}
  end

  defmodule HaltingPlug do
    import Plug.Conn
    def call(conn, :options) do
      halt(conn)
    end
  end

  test "handle to halt, exits with normal reason" do
    Process.flag :trap_exit, true
    pid = spawn_link Pastelli.Handler, :handle, [build_req, {HaltingPlug, :options}]
    assert_receive {:'EXIT', ^pid, :normal}
  end


end
