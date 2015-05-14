defmodule Pastelli.Handler do
  require Logger

  alias :elli_request, as: Request

  def init(_req, {_plug, _opts}) do
    :ignore
  end

  def handle(req, {plug, opts}) do
    Pastelli.Connection.build_from(req)
    |> plug.call(opts)
    |> process_connection(plug)
  end

  defp log(what, header\\"") do
    Logger.debug "#{header}\n#{inspect(what)}\n"
    what
  end

  defp process_connection(%Plug.Conn{state: :sent}=conn, _plug) do
    {conn.status, conn.resp_headers, conn.resp_body}
  end

  defp process_connection(%Plug.Conn{state: :chunked}=conn, _plug) do
    {:chunk, conn.resp_headers, conn.assigns[:init_chunk] || ""}
  end

  defp process_connection(%Plug.Conn{halted: :true}, _plug) do
    exit(:normal)
  end

  # Elli Event handlers

  def handle_event :chunk_complete, [req, 200, _headers, _end, _timings], _args do
    Process.exit Request.chunk_ref(req), :shutdown
    :ok
  end

  def handle_event(other, _foo, _bar) do
    log "[EVENT]: #{inspect(other)} -- #{inspect(_foo)} -- #{inspect(_bar)}"
    :ok
  end

end
