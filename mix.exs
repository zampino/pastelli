defmodule Pastelli.Mixfile do
  use Mix.Project

  def project do
    [app: :pastelli,
     description: "An Elixir Plug Adapter with a focus on chunked streaming connections for Elli server",
     version: "0.1.1",
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
      {:plug, github: "elixir-lang/plug", optional: true},
      {:elli, github: "knutin/elli"},
      {:elli_websocket, github: "zampino/elli_websocket", branch: "fix_erlang_otp_18_record_type", compile: "make test compile"},
      {:hackney, "~> 1.3", only: :test},
      {:mock, "~> 0.1", only: :test}
    ]
  end
end
