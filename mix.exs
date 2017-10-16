defmodule Bridge.Mixfile do
  use Mix.Project

  def project do
    [
      app: :bridge,
      version: "0.1.0",
      elixir: "~> 1.5",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description(),
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      # define the application module (:mod) callback and args
      mod: {Bridge.Application, []}
    ]
  end
  
  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end
  
  defp description do
    ~S"""
    Bridge is a means of connecting HTTP and Websocket APIs.
    """
  end
  
  defp package do
    [
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["Micah Rye"],
      licenses: ["MIT"],
   ]
  end
end
