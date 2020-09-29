defmodule Iodevice.TakePicture do
  use GenServer
  #alias Iodevice.Configuration
  alias Iodevice.Camera
  #alias Iodevice.TakePicture
  require Logger

  #defstruct data: nil, interval: 100

  @camera "camera"
  @width 400
  @height 400

  def subscribe(name) do
    pid = Swarm.whereis_name(name)
    Enum.each(@camera, &(Swarm.join(&1, pid)))
  end

  @defaultstate %{data: nil, interval: 100, size: {@width, @height} }

  def start_link(name \\ :takepicture) do
    Logger.info("TakePicture->start_link(#{name})")
    #GenServer.start_link(__MODULE__, %{data: nil, interval: 100}, name: {:via, :swarm, name})
    GenServer.start_link(__MODULE__, @defaultstate, name: __MODULE__)
  end

  def init(state) do
    Camera.set_size(@width,@height)
    data = Camera.next_frame()
    Logger.info("TakePicture->init(#{inspect state})")
    set_interval(:init, 500)
    #{:ok, timer} = :timer.send_interval(state[:interval], :expose)
    {:ok, %{state | data: data}}
  end

  def handle_call(:take, _from, %{data: data} = state) do

    {:reply, data, state}
  end

  def handle_info(:init, state) do
    check_node(Node.alive?(), 500, state)
    {:noreply, state}
  end
  def handle_info(:expose,state) do
    data = Camera.next_frame()
    pid = :global.whereis_name(:camera_pos)
    send(pid, {:put, data})
    #GenServer.cast(pid, {:put, data})
    {:noreply, %{state | data: data}}
  end

  def set_interval(msg, ms) do
    # to handle_info/2
    Process.send_after(self(), msg, ms)
  end
  defp check_node(true, _timer, state) do
    Swarm.register_name(:picture, self())
    :timer.send_interval(state[:interval], :expose)
  end

  defp check_node(_,    timer, _state), do: set_interval(:init,  timer)


end
