defmodule Pastelli.Router do
  defmacro __using__(_options) do
    quote do
      use Plug.Router
      import Pastelli.Router
      import Pastelli.Conn
    end
  end

  defmacro stream(path, contents) do
    body = contents[:do]
    new_body = quote do
      var!(conn) = put_resp_content_type(var!(conn), "text/event-stream")
      |> send_chunked(200)
      unquote(body)
    end
    quote do
      get(unquote(path), do: unquote(new_body))
    end
  end
end
