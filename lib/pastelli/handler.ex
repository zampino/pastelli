defmodule Pastelli.Handler do
  require Logger
  # @behaviour :elli_handler
  alias :elli_request, as: Request

  def init(req, {_plug, _opts}) do
    log inspect(req), "////////// request incoming ////////////"
    :ignore
  end

  def handle(req, {plug, opts}) do
    Pastelli.Connection.build_from(req)
    |> plug.call(opts)
    |> log("((((((((((((( plug called ))))))))))))")
    |> process_connection(plug)
  end

  defp log(what, header\\"") do
    Logger.debug "#{header}\n#{inspect(what)}\n"
    what
  end

  defp process_connection(%Plug.Conn{state: :sent}=conn, _plug) do
    log "||||||| connection being sent |||||||"
    {conn.status, conn.resp_headers, conn.resp_body}
  end

  defp process_connection(%Plug.Conn{state: :chunked}=conn, _plug) do
    log "||||||| connection being sent |||||||"
    {:chunk, conn.resp_headers, conn.assigns.init_chunk || ""}
  end

  defp process_connection(%Plug.Conn{halted: :true}=conn, _plug) do
    log "||||||| connection being halted |||||||"
    exit(:normal)
  end

  # Elli Event handlers

  def handle_event :elli_startup, _, _ do
    log "!!! elli started !!!"
    :ok
  end

  def handle_event :request_parse_error, args1, args2 do
    log "#{inspect(args1)} -- #{inspect(args2)}", "!!!! request parse error !!!!!!"
    :ok
  end

  def handle_event :chunk_complete, [req, 200, _headers, _end, _timings], _args do
    log "#{inspect(req)}\n#{inspect(_headers)}\n#{inspect(_args)}", "}}}}} chunk completed {{{{{"
    Process.exit Request.chunk_ref(req), :unknown
    :ok
  end

  def handle_event :request_error, [_req, err, stacktrace], _args do
    log "#{inspect(err)}\n" <>
      "#{inspect(stacktrace)}\n", "--------------------- ERROR -----------------------------------------"
  end

  def handle_event(other, _foo, _bar) do
    IO.puts "[EVENT]: #{inspect(other)} -- #{inspect(_foo)} -- #{inspect(_bar)}"
  end

end
