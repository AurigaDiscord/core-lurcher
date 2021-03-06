defmodule Lurcher.Mixfile do
  use Mix.Project

  def project do
    [
      app: :lurcher,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Lurcher, []},
      applications: [:confex, :websockex, :poison, :amqp],
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:confex, "~> 3.3.0"},
      {:websockex, "~> 0.4.1"},
      {:poison, "~> 3.1"},
      {:amqp, "~> 1.0.3"}
    ]
  end
end
