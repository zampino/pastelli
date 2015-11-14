defmodule Pastelli.Conn do
  import Plug.Conn, only: [chunk: 2, put_private: 3]

  def init_chunk(%Plug.Conn{state: :chunked} = conn, data) do
    put_private(conn, :init_chunk, event_chunk_data(data))
  end

  def init_chunk(%Plug.Conn{state: :chunked} = conn, data, options)
    when is_list(options) do
    put_private(conn, :init_chunk, event_chunk_data(data, options))
  end

  def close_chunk(%Plug.Conn{adapter: {adapter, req}, status: :chunked} = conn) do
    adapter.close_chunk(req)
    conn
  end

  def close_chunk(%Plug.Conn{}) do
    raise ArgumentError, message: "close_chunk/1 expects a chunked response. "
      <> "Please ensure you have called send_chunked/2 before you close the connection."
  end

  def event(%Plug.Conn{state: :chunked} = conn, body) do
    chunk(conn, event_chunk_data(body))
  end

  def event(%Plug.Conn{state: :chunked} = conn, body, options) do
    chunk(conn, event_chunk_data(body, options))
  end

  def event(%Plug.Conn{}) do
    raise ArgumentError, message: "event/2 expects a chunked response. "
      <> "Please ensure you have called send_chunked/2 before you send something."
  end

  defp event_chunk_data(data), do: "data: #{encode(data)}\n\n"
  defp event_chunk_data(data, options) when is_list(options) do
    meta = Enum.reduce([:event, :id, :retry], [], fn(key, meta) ->
      value = Keyword.get options, key
      if value, do: meta ++ ["#{key}: #{value}\n"], else: meta
    end) |> Enum.join
    "#{meta}#{event_chunk_data(data)}"
  end

  defp encode(data) when is_binary(data), do: data
  defp encode(data) when is_map(data) or is_list(data) do
    Poison.encode_to_iodata! data
  end
  defp encode(_), do: raise(ArgumentError, message: "what are you trying to send?")
end
