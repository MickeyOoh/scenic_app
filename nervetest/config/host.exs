use Mix.Config

config :nervetest, :viewport, %{
  name: :main_viewport,
  # default_scene: {Nervetest.Scene.Crosshair, nil},
  default_scene: {Nervetest.Scene.SysInfo, nil},
  size: {800, 480},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      opts: [title: "MIX_TARGET=host, app = :nervetest"]
    }
  ]
}
