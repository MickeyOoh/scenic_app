defmodule Nervetest.Component.Camera do
  use Scenic.Component

  alias Scenic.ViewPort
  alias Scenic.Graph
  require Logger

  import Scenic.Primitives, only: [{:rect, 3}, {:update_opts, 2}]

  @width 150
  @height 150

  # @indent 30
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

    :global.register_name(:camera_pos, self())

    pid = Swarm.whereis_name(:picture)
    data =  get_picture(pid)
    #hash = Scenic.Cache.Support.Hash.binary!(data, :sha)
    #Scenic.Cache.Static.Texture.load(path, hash)
    Scenic.Cache.Dynamic.Texture.put_new("camera_frame", {:ga, 400, 400, data, []})
    position = {400,400}
    graph = Graph.build()
              |> rect(
                  {400, 400},
                  id: :camera,
                  #fill: {:image, {hash,255} }
                  fill: {:dynamic, "camera_frame"}
                )
              |> Graph.modify( :camera, &update_opts(&1, translate: position))

    {:ok, %{graph: graph, viewport: opts[:viewport]}, push: graph}
  end

  def handle_info({:put, data}, %{graph: graph} = state) do
    #hash = Scenic.Cache.Support.Hash.binary!(data, :sha)
    Scenic.Cache.Dynamic.Texture.put("camera_frame", {:g, 400, 400, data, []})
    graph =
      Graph.modify(
        graph,
        :camera,
        #&update_opts(&1, fill: {:image, hash})
        &update_opts(&1, fill: {:dynamic, "camera_frame"})

        #&update_opts(&1, translate: position)
      )
    {:noreply, state, push: graph}
  end

  defp get_picture(:undefined) do
    path = :code.priv_dir(:nervetest)
              |> Path.join("/static/images/racoondog.jpg")
    File.read!(path)
  end
  defp get_picture(pid), do: GenServer.call(pid, :take)

end
