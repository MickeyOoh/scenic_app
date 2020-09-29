defmodule Nervetest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @target Mix.target()

  require Logger;

  use Application

  def start(_type, _args) do
    #ConnectNode.start_link()
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SnTest.Supervisor]
    Supervisor.start_link(children(@target), opts)
  end

  # List all child processes to be supervised
  def children("host") do
    main_viewport_config = Application.get_env(:nervetest, :viewport)

    [
      Nervetest.Sensor.Supervisor,
      {Scenic, viewports: [main_viewport_config]}
    ]
  end

  def children(_target) do
    main_viewport_config = Application.get_env(:nervetest, :viewport)
    Logger.debug("main_viewport_config-> #{inspect main_viewport_config}")
    [
      Nervetest.Sensor.Supervisor,
      {Scenic, viewports: [main_viewport_config]},
      {Connect_Node, []}
    ]
  end
end
