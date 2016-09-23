defmodule Helmsman.Mixfile do
  use Mix.Project

  def project do
    [app: :helmsman,
     version: "0.1.0",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_paths: elixirc_paths(Mix.env),
     dialyzer: [plt_add_deps: :transitive,
      flags: [ "-Werror_handling", "-Wrace_conditions", "-Woverspecs", "-Wunderspecs", "-Wspecdiffs", "-Wunknown" ]],
     deps: deps]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      mod: {Helmsman.App, []},
      applications: [
        :logger,
        :dbux,
        :httpoison,
        :yaml_elixir
      ]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:dbux, git: "https://github.com/khamilowicz/dbux"},
      {:mapmaker, in_umbrella: true},
      {:httpoison, "~> 0.9"},
      {:yaml_elixir, "~> 1.1"}
    ]
  end
end
