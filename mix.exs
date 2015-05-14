defmodule Pastelli.Mixfile do
  use Mix.Project

  def project do
    [app: :pastelli,
     description: "An Elixir Plug Adapter with a focus on chunked streaming connections for Elli server",
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:plug, github: "elixir-lang/plug"},
      {:elli, github: "knutin/elli"},
      {:hackney, "~> 0.13", only: :test}
    ]
  end
end
