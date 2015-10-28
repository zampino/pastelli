defmodule Pastelli.Router do
  defmacro __using__(_options) do
    quote do
      use Plug.Router

      defmacro stream(path, body) do
        get(unquote(path), body)
      end
    end
  end


end
