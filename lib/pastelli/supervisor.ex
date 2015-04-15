defmodule Pastelli.Supervisor do
  use Supervisor

  def start_link ref, options do
    Supervisor.start_link __MODULE__, {ref, options}, []
  end

  def init({ref, options}) do
    children = [
      worker(:elli, [options], [id: ref])
    ]
    supervise children, strategy: :one_for_one
  end

  def shutdown(ref) do
    case Supervisor.terminate_child(__MODULE__, ref) do
      :ok -> Supervisor.delete_child(__MODULE__, ref)
      error -> error
    end
  end
end
