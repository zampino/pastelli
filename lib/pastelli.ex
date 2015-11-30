defmodule Pastelli do
  require Logger
  @moduledoc """
  Adapter interface to the Elli webserver.

  ## Options

  * `:ip` - the ip to bind the server to.
    Must be a tuple in the format `{x, y, z, w}`.

  * `:port` - the port to run the server.
    Defaults to 4000 (http)

  * `:acceptors` - the number of acceptors for the listener.
    Defaults to 20.

  * `:max_connections` - max number of connections supported.
    Defaults to `:infinity`.

  * `:ref` - the reference name to be used.
    Defaults to `plug.HTTP` (http) and `plug.HTTPS` (https).
    This is the value that needs to be given on shutdown.

  """

  @doc """
  Run elli under http.

  ## Example

      # Starts a new interface
      Plug.Adapters.Elli.http MyPlug, [], port: 80

      # shut it down
      Plug.Adapters.Elli.shutdown MyPlug.HTTP

  """
  @spec http(module(), Keyword.t, Keyword.t) ::
      {:ok, pid} | {:error, :eaddrinuse} | {:error, term}
  def http(plug, options, elli_options) do
    run(:http, plug, options, elli_options)
  end

  def https(_plug, _options, _elli_options) do
    raise ArgumentError, message: "NotImplemented"
  end

  def shutdown(ref) do
    Pastelli.Supervisor.shutdown(ref)
  end

  @doc """
    returns a child spec for elli to be supervised in your application
  """
  import Supervisor.Spec
  def child_spec(scheme, plug, options, elli_options) do
    {id, elli_options} = Keyword.pop elli_options, :supervisor_id, :elli
    args = build_elli_options(scheme, plug, options, elli_options)
    worker(:elli, [args], id: id)
  end

  defp run(scheme, plug, options, elli_options) do
    Pastelli.Supervisor.start_link(
      ref_for(plug),
      build_elli_options(scheme, plug, options, elli_options)
    )
  end

  def build_elli_options(_scheme, plug, options, elli_options) do
    default_elli_options
    |> Keyword.put(:callback_args, {plug, options})
    |> Keyword.merge(elli_options)
  end

  defp default_elli_options do
    [
      port: 4000,
      callback: Pastelli.Handler
    ]
  end

  defp ref_for(plug) do
    Module.concat plug, "HTTP"
  end

end
