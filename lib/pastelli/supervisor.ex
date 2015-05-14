defmodule Pastelli.Supervisor do
  use Supervisor
  require Logger

  def start_link ref, options do
    Supervisor.start_link __MODULE__, options, name: ref
  end

  def init(options) do
    children = [
      worker(:elli, [options], id: :elli)
    ]
    supervise children, strategy: :one_for_one
  end

  def shutdown(ref) do
    case Supervisor.terminate_child(ref, :elli) do
      :ok -> Supervisor.delete_child(ref, :elli)
      error -> error
    end
  end
end
