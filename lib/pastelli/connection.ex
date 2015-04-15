defmodule Pastelli.Connection do
  alias :elli_request, as: Request

  def build_from(req) do
    headers = Request.headers(req)
    host_port = Enum.find_value headers, fn({name, value})->
      (name == "Host") && value
    end
    [host, port] = String.split(host_port, ":")
    req_headers = downcase_keys(headers)
    |> ensure_origin(host_port)

    {:req,
      method,
      _path,
      _args,
      raw_path,
      _version,
      _headers,
      _body,
      pid,
      _socket,
      _callback} = req

    %Plug.Conn{
      adapter: {__MODULE__, req},
      host: host,
      port: port,
      method: Request.method(req) |> to_string(),
      # "#{method}",
      owner: self,
      peer: Request.peer(req),
      path_info: split_path(raw_path),
      query_string: Request.query_str(req),
      req_headers: req_headers,
      scheme: :http
    } |> Plug.Conn.put_private :plug_stream_pid, pid
  end

  ## Plug.Conn API ##

  def read_req_body(req, options) do
    # {:req,
    #   _method,
    #   _path,
    #   _args,
    #   raw_path,
    #   _version,
    #   _headers,
    #   body,
    #   _pid,
    #   _socket,
    #   _callback} = req
    # IO.puts "\n -------- reading request body -------\n#{inspect(body)}\n\n"
    {:ok, Request.body(req), req}
  end

  def send_resp(req, status, headers, body) do
    {:ok, body, req}
  end

  def send_chunked(req, status, headers) do
    {:ok, nil, req}
  end

  def chunk(req, body) do
    pid = Request.chunk_ref(req)
    IO.puts "\n --- about to send chunk ---"
    res = Request.async_send_chunk pid, body
    IO.puts "\n --- chunk sent #{inspect(res)}"
    :ok
  end

  ##

  defp downcase_keys(headers) do
    downcase_key = fn({key, value})->
      {String.downcase(key), value}
    end
    Enum.map headers, downcase_key
  end

  defp ensure_origin(headers, origin) do
    get_origin = fn({name, value})->
      (name == "origin") && value
    end
    case Enum.find_value(headers, get_origin) do
      nil -> [{"origin", origin} | headers]
      _ -> headers
    end
  end

  defp split_path(path) do
    segments = :binary.split(path, "/", [:global])
    for segment <- segments, segment != "", do: segment
  end
end
