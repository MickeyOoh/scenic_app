defmodule Nervetest.Component.Nav do
  use Scenic.Component

  alias Scenic.ViewPort
  alias Scenic.Graph

  import Scenic.Primitives, only: [{:text, 3}, {:rect, 3}]
  import Scenic.Components, only: [{:dropdown, 3}]
  import Scenic.Clock.Components

  # import IEx
  require Logger

  @height 60

  # --------------------------------------------------------
  def verify(scene) when is_atom(scene), do: {:ok, scene}
  def verify({scene, _} = data) when is_atom(scene), do: {:ok, data}
  def verify(_), do: :invalid_data

  # ----------------------------------------------------------------------------
  def init(current_scene, opts) do
    styles = opts[:styles] || %{}

    # Get the viewport width
    {:ok, %ViewPort.Status{size: {width, _}}} =
      opts[:viewport]
      |> ViewPort.info()

    graph =
      Graph.build(styles: styles, font_size: 20)
      |> rect({width, @height}, fill: {48, 48, 48})
      |> text("Scene:", translate: {14, 35}, align: :right)
      |> dropdown(
        {[
           {"Sensor", Nervetest.Scene.Sensor},
           {"Sensor (spec)", Nervetest.Scene.SensorSpec},
           {"Primitives", Nervetest.Scene.Primitives},
           {"Components", Nervetest.Scene.Components},
           {"Transforms", Nervetest.Scene.Transforms}
         ], current_scene},
        id: :nav,
        translate: {70, 15}
      )
      |> digital_clock(text_align: :right, translate: {width - 20, 35})
    Logger.warn("nav.graph:#{inspect graph}")

    {:ok, %{graph: graph, viewport: opts[:viewport]}, push: graph}
  end

  # ----------------------------------------------------------------------------
  def filter_event({:value_changed, :nav, scene}, _, %{viewport: vp} = state)
      when is_atom(scene) do
    ViewPort.set_root(vp, {scene, nil})
    {:halt, state}
  end

  # ----------------------------------------------------------------------------
  def filter_event({:value_changed, :nav, scene}, _, %{viewport: vp} = state) do
    ViewPort.set_root(vp, scene)
    {:halt, state}
  end
end
