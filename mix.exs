defmodule Pastelli.Mixfile do
  use Mix.Project
  @version "0.2.3"

  def project do
    [app: :pastelli,
     description: "An Elixir Plug Adapter with a focus on chunked streaming connections for Elli server",
     version: @version,
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:plug, "~> 1.0"},
      {:elli, github: "knutin/elli"},
      {:elli_websocket, github: "mmzeeman/elli_websocket", compile: "make test compile"},
      {:poison, "~> 1.3.0"},
      {:hackney, "~> 1.3", only: :test},
      {:mock, "~> 0.1", only: :test}
    ]
  end
end
