defmodule MjpegExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :mjpeg_example,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MjpegExample.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:mjpeg, github: "lawik/mjpeg"},
      {:egd, github: "erlang/egd"},
      {:mogrify, "~> 0.8.0"},
      {:chisel, "~> 0.2.0"}

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
