defmodule Nervetest.Component.Mouse do
  use Scenic.Component

  alias Scenic.ViewPort
  alias Scenic.Graph
  require Logger

  import Scenic.Primitives, only: [{:rect, 3}, {:update_opts, 2}]

  @icon_width 30
  @icon_height 30
  @target_path "/srv/erlang"

  # @graph Graph.build()
  #        |> rect(
  #          {@icon_width, @icon_height},
  #          id: :corsor,
  #          fill: {:image, {@parrot_hash, 0}}
  #        )

  # @indent 30
  def priv_dir() do
    vsn = :"0.1.0"
    appname = to_string(:nervetest) <> "-" <> to_string(vsn)
    path = Path.join([@target_path, "lib", appname, "priv"])
           |> Path.join("/static/images/icons_cursor30.png")
    hash = Scenic.Cache.Support.Hash.file!(path, :sha)
    {path, hash}
  end

  # --------------------------------------------------------
  def verify(scene) when is_atom(scene), do: {:ok, scene}
  def verify({scene, _} = data) when is_atom(scene), do: {:ok, data}
  def verify(_), do: :invalid_data

  # ----------------------------------------------------------------------------
  def init(current_scene, opts) do
    # Get the viewport width
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} =
      opts[:viewport]
      |> ViewPort.info()
      
    :global.register_name(:mouse_pointer, self())

    {path, hash} = priv_dir()
    Logger.warn("viewport:#{inspect opts[:viewport]} image: #{path}")
    # load the parrot texture into the cache
    #Scenic.Cache.Static.Texture.load(@parrot_path, @parrot_hash)
    Scenic.Cache.Static.Texture.load(path, hash)
    position = {200,200}
    # move the parrot into the right location
    # graph = Graph.modify(@graph, :parrot, &update_opts(&1, translate: position))
    graph = Graph.build()
              |> rect(
                    {@icon_width, @icon_height},
                  id: :cursor,
                  fill: {:image, {hash, 255}}
                )
              |> Graph.modify(   :cursor, &update_opts(&1, translate: position))
    Logger.warn("mouse.graph:#{inspect graph}")

    {:ok, %{graph: graph, viewport: opts[:viewport], path: {path, hash}}, push: graph}
  end

  def handle_info({:position, position}, %{graph: graph, path: {path, hash}} = state) do
    #{path, hash} = priv_dir()

    graph =
      Graph.modify(
        graph,
        :cursor,
        # &update_opts(&1, fill: {:image, {@parrot_hash, alpha}})
        &update_opts(&1, translate: position)
      )

    {:noreply, state, push: graph}
  end

end
