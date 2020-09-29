defmodule Firm.Detect do
  use GenServer
  @motion_sencitivity 0.1

  require Logger

  def start_link(_arg) do
    state = %{ count: 0}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_info(:tick, state) do
    {:noreply, state}
  end
  def handle_call(:din, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:detect_motion, image}, %{count: previous_count}=state) do
    count = image |> :binary.bin_to_list( ) |> Enum.sum()
    percentage = previous_count + @motion_sencitivity

    if count < previous_count - percentage or
        count > previous_count + percentage do
      Logger.info("Moving: #{count}")  
    end

    {:noreply, %{state | count: count}}
  end
  def handle_cast(msg, state) do

    {:noreply, state}
  end

  ##
  def detect_montion(image) do
    GenServer.cast(__MODULE__, {:detect_motion, image})
  end
end