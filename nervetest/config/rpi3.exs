use Mix.Config

config :nervetest, :viewport, %{
  name: :main_viewport,
  default_scene: {Nervetest.Scene.Splash, Nervetest.Scene.Sensor},
  size: {1920, 1080},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: Scenic.Driver.Nerves.Rpi
    },
    # %{
    #   module: Scenic.Driver.Nerves.Touch,
    #   opts: [
    #     device: "FT5406 memory based driver",
    #     calibration: {{1, 0, 0}, {1, 0, 0}}
    #   ]
    # }

    # %{
    #   module: Scenic.Driver.Nerves.Input,
    #   opts: [
    #     device: "Mouse",
    #   ]
    # }

  ]
}
