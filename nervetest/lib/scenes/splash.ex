defmodule Nervetest.Scene.Splash do
  @moduledoc """
  Sample splash scene.

  This scene demonstrate a very simple animation and transition to another scene.

  It also shows how to load a static texture and paint it into a rectangle.
  """

  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [{:rect, 3}, {:update_opts, 2}]

  require Logger

  @target Mix.target()
  @target_path "/srv/erlang"

  @parrot_path :code.priv_dir(:nervetest)
               |> Path.join("/static/images/scenic_parrot.png")
  @parrot_hash Scenic.Cache.Support.Hash.file!(@parrot_path, :sha)

  # @parrot_width 62
  # @parrot_height 114
  @parrot_width 410
  @parrot_height 234
  @graph Graph.build()
         |> rect(
           {@parrot_width, @parrot_height},
           id: :parrot,
           fill: {:image, {@parrot_hash, 0}}
         )

  @animate_ms 30
  @finish_delay_ms 3000

  # --------------------------------------------------------
  def init(first_scene, opts) do
    viewport = opts[:viewport]
    
    # calculate the transform that centers the parrot in the viewport
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    position = {
      vp_width / 2 - @parrot_width / 2,
      vp_height / 2 - @parrot_height / 2
    }
    {path, hash} = priv_dir(Application.get_env(:nervetest, :target))
    Logger.debug("viewport:#{inspect viewport} image: #{path} #{inspect position}")
    # load the parrot texture into the cache
    #Scenic.Cache.Static.Texture.load(@parrot_path, @parrot_hash)
    Scenic.Cache.Static.Texture.load(path, hash)

    # move the parrot into the right location
    # graph = Graph.modify(@graph, :parrot, &update_opts(&1, translate: position))
    graph = Graph.build()
              |> rect(
                    {@parrot_width, @parrot_height},
                  id: :parrot,
                  fill: {:image, {hash, 0}}
                )
              |> Graph.modify(   :parrot, &update_opts(&1, translate: position))

    # start a very simple animation timer
    {:ok, timer} = :timer.send_interval(@animate_ms, :animate)

    state = %{
      viewport: viewport,
      timer: timer,
      graph: graph,
      first_scene: first_scene,
      alpha: 0
    }
    Logger.warn("splash.graph:#{inspect graph}")
    {:ok, state, push: graph}
  end
  def priv_dir("host"), do: {@parrot_path, @parrot_hash}

  def priv_dir(_target) do
    vsn = :"0.1.0"
    appname = to_string(:nervetest) <> "-" <> to_string(vsn)
    path = Path.join([@target_path, "lib", appname, "priv"])
           |> Path.join("/static/images/scenic_structure.png")
    hash = Scenic.Cache.Support.Hash.file!(path, :sha)
    {path, hash}
  end
  # --------------------------------------------------------
  # A very simple animation. A timer runs, which increments a counter. The counter
  # Is applied as an alpha channel to the parrot png.
  # When it is fully saturated, transition to the first real scene
  def handle_info(
        :animate,
        %{timer: timer, alpha: a} = state
      )
      when a >= 256 do
    :timer.cancel(timer)
    IO.puts "*** file-> #{inspect @parrot_path}"
    Process.send_after(self(), :finish, @finish_delay_ms)
    {:noreply, state}
  end

  def handle_info(:finish, state) do
    go_to_first_scene(state)
    {:noreply, state}
  end

  def handle_info(:animate, %{alpha: alpha, graph: graph} = state) do
    {path, hash} = priv_dir(Application.get_env(:nervetest, :target))

    graph =
      Graph.modify(
        graph,
        :parrot,
        # &update_opts(&1, fill: {:image, {@parrot_hash, alpha}})
        &update_opts(&1, fill: {:image, {hash, alpha}})
      )

    {:noreply, %{state | graph: graph, alpha: alpha + 2}, push: graph}
  end

  # --------------------------------------------------------
  # short cut to go right to the new scene on user input
  def handle_input({:cursor_button, {_, :press, _, _}}, _context, state) do
    go_to_first_scene(state)
    {:noreply, state}
  end

  def handle_input({:key, _}, _context, state) do
    go_to_first_scene(state)
    {:noreply, state}
  end

  def handle_input(_input, _context, state), do: {:noreply, state}

  # --------------------------------------------------------
  defp go_to_first_scene(%{viewport: vp, first_scene: first_scene}) do
    ViewPort.set_root(vp, {first_scene, nil})
  end
end
