defmodule PubSub do
  require Logger
  use GenServer

  def pubsuber(name) do
    GenServer.start_link(__MODULE__, name, name: {:via, :swarm, name})
  end

  @impl GenServer
  def init(name) do
    Logger.warn("#{__MODULE__}.init: start for #{inspect(name)}")
    {:ok, {name, []}}
  end

  def register_subscription_topics(name, topics) do
    Logger.warn("#{__MODULE__} register: #{inspect(name)} subscribes #{topics}")
    pid = Swarm.whereis_name(name)
    Enum.each(topics, &(Swarm.join(&1, pid)))
  end

  def register_publication_topics(name, topics) do
    GenServer.cast(Swarm.whereis_name(name), {:pubtopics, topics})
  end

  def publish(publisher, msg) do
    send(Swarm.whereis_name(publisher), {:publish, {:kickpub, msg}})
  end

  @impl GenServer
  def handle_cast({:pubtopics, topics}, {name, _pub_topics}) do
    {:noreply, {name, topics}}
  end

  @impl GenServer
  def handle_info({:publish, {publisher, msg}}, {name, []}) do
    Logger.warn("#{__MODULE__} handle_info: #{inspect(name)} gets #{inspect({publisher, msg})}")
    {:noreply, {name, []}}
  end

  @impl GenServer
  def handle_info({:publish, {publisher, msg}}, {name, pub_topics}) do
    Logger.warn("#{__MODULE__} handle_info: #{inspect(name)} gets #{inspect({publisher, msg})}")
    Enum.each(pub_topics, &(Swarm.publish(&1, {:publish, {name, msg}})))
    {:noreply, {name, pub_topics}}
  end
end