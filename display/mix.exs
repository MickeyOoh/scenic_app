defmodule Display.MixProject do
  use Mix.Project

  def project do
    [
      app: :display,
      version: "0.1.0",
      elixir: "~> 1.7",
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Display, []},
      extra_applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:scenic, path: "../scenic"},
      {:scenic_driver_glfw, path: "../scenic_driver_glfw", targets: :host},
      # {:scenic, "~> 0.10"},
      # {:scenic_driver_glfw, "~> 0.10", targets: :host},

      {:swarm, "~> 3.4"},
    ]
  end
end
