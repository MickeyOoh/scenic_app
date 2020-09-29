defmodule Display.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  # import Scenic.Components

  @note """
    This is a very simple starter application.

    If you want a more full-on example, please start from:

    mix scenic.new.example
  """

  @text_size 24

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])

    # show the version of scenic and the glfw driver
    scenic_ver = Application.spec(:scenic, :vsn) |> to_string()
    glfw_ver = Application.spec(:scenic, :vsn) |> to_string()

    file = :code.priv_dir(:display)
            |> Path.join("/static/images/racoondog.jpg")
    data = File.read!(file)
    hash = Scenic.Cache.Support.Hash.binary!(data, :sha)
    Scenic.Cache.Static.Texture.put_new(hash, data)
    #Scenic.Cache.Dynamic.Texture.put_new("camera_frame", {:rgba, 150, 150, data, []})

    graph =
      Graph.build(font: :roboto, font_size: @text_size)
      |> add_specs_to_graph([
        text_spec("scenic: v" <> scenic_ver, translate: {20, 40}),
        text_spec("glfw: v" <> glfw_ver, translate: {20, 40 + @text_size}),
        text_spec(@note, translate: {20, 120}),
        rect_spec({width, height})
      ])
      |> rect( {150, 150}, id: :camera,
        #fill: {:dynamic, "camera_frame" },
        fill: {:image, {hash, 255}},
        #fill: :white,
        translate: {100, 300}
      )
      #|> circle(10, fill: :white, translate: {5, 5})
      #|> circle(10, fill: :white, translate: {5, 5}, matrix: Scenic.Math.Matrix.build_translation({5, 5}))

    {:ok, graph, push: graph}
  end

  def handle_input(event, _context, state) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, state}
  end
  # def handle_info({:put, data}, %{graph: graph, hash: hash} = state) do
  #   #hash = Scenic.Cache.Support.Hash.binary!(data, :sha)
  #   Scenic.Cache.Dynamic.Texture.put("camera_frame", {:rgb, 400, 400, data, []})
  #   graph =
  #     Graph.modify(
  #       graph,
  #       :camera,
  #       #&update_opts(&1, fill: {:image, hash})
  #       &update_opts(&1, fill: {:dynamic, "camera_frame"})

  #       #&update_opts(&1, translate: position)
  #     )
  #   {:noreply, state, push: graph}
  # end

  def set_interval(msg, ms) do
    # to handle_info/2
    Process.send_after(self(), msg, ms)
  end
end
