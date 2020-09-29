defmodule Connect_Node do
  use GenServer
  require Logger

  @interval_init_ms 1_000
  @interval_wakeup_ms 1_000
  @interval_alive_ms 60_000
  @interval_alive_false_ms 1_000

  @node_name "master"
  @node_cookie "chocolatechip"

  def start_link(node_option \\ []) do
    GenServer.start_link(__MODULE__, node_option, name: __MODULE__)
  end

  def init(_node_option) do
    # get node domain from config
    {:ok, node_domain} = :inet.gethostname()
    node_domain = List.to_string(node_domain) <> ".local"     # #{domain}.local
    state = %{
      address: nil,                     # ip address
      node_domain: node_domain,         # domain name
      node_name: "#{@node_name}@#{node_domain}",# node name
      node_cookie: @node_cookie,        #
      conn_nodes: ["node1@nerves.local"],
    }
    # when connection changes, it receive msg from Vintage
    # in case of net wake up already before the abvoe subscribe, the following steps are needed
    state = init_nodeconn(:internet, state)

    {:ok, state}
  end

  def handle_info(:init, state) do
    state = init_nodeconn(:internet, state)
    {:noreply, state}
  end

  def handle_info(:wakeup, state) do
    nodeconn(state)
    {:noreply, state}
  end

  def handle_info(:alive, state) do
    re_nodeconn(conn_node_alive?(state), state)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.info("connect msg:#{inspect msg}")
    Logger.info("addresses:#{inspect VintageNet.get_by_prefix(["interface","wlan0","addresses"])}")
    {:noreply, state}
  end

  defp init_nodeconn(:internet, %{node_name: node_name, node_cookie: cookie} = state) do
    Node.start(:"#{node_name}")
    Node.set_cookie(:"#{cookie}")
    {:ok, [{ipaddress, _, _} | t]} = :inet.getif()
    ipaddr = :inet.ntoa(ipaddress) |> List.to_string()

    Logger.info("=== Node.start -> #{node_name} ===")
    Logger.info("=== Node.set_cookie -> #{cookie} ===")

    case [node_start?(), node_set_cookie?()] do
      [true, true] ->
        Logger.info("=== init_nodeconn -> success! Node.start & Node.set ===")
        set_interval(:wakeup, @interval_wakeup_ms)

      [_, _] ->
        Logger.info("=== init_nodeconn -> false, node_start(#{inspect(node_start?())}), node_set_cookie(#{inspect(node_set_cookie?())}) ===")
        set_interval(:init, @interval_init_ms)
    end
    %{state | address: ipaddr}
  end

  defp init_nodeconn(msg, state) do
    Logger.info("=== init_nodeconn -> #{inspect(msg)} ===")
    #set_interval(:init, @interval_init_ms)
    state
  end

  defp nodeconn(%{conn_nodes: conn_node} = state) do
    conn = Node.connect(:"#{conn_node}")
    ##Logger.info("=== Node.connect -> try connect to #{conn_node} ===")

    case conn do
      true ->
        Logger.info("=== nodeconn -> #{conn} ===")
        set_interval(:alive, @interval_alive_ms)

      _ ->
        set_interval(:wakeup, @interval_wakeup_ms)
    end
  end

  defp re_nodeconn(:node_alive, _) do
    set_interval(:alive, @interval_alive_ms)
  end

  defp re_nodeconn(:node_re_conn, [_, _, conn_node]) do
    conn = Node.connect(:"#{conn_node}")
    Logger.info("=== re_nodeconn Node.connect -> #{conn_node} ===")

    case conn do
      true ->
        Logger.info("=== re_nodeconn -> #{conn} ===")
        set_interval(:alive, @interval_alive_ms)

      _ ->
        set_interval(:alive, @interval_alive_false_ms)
    end
  end

  defp re_nodeconn(:node_down, [_, _, conn_node]) do
    Logger.debug("=== re_nodeconn -> false... try connect to #{conn_node} ====")
    set_interval(:alive, @interval_alive_false_ms)
  end

  def node_start?() do
    case Node.self() do
      :nonode@nohost -> false
      _ -> true
    end
  end

  def node_set_cookie?() do
    case Node.get_cookie() do
      :nocookie -> false
      _ -> true
    end
  end

  def conn_node_alive?([_, _, conn_node]) do
    case [conn_node_list_find?(conn_node), conn_node_ping?(conn_node)] do
      [true, true] -> :node_alive
      [false, true] -> :node_re_conn
      [_, _] -> :node_down
    end
  end

  def conn_node_list_find?(conn_node) do
    case Node.list() |> Enum.find(fn x -> x == :"#{conn_node}" end) do
      nil -> false
      _ -> true
    end
  end

  def conn_node_ping?(conn_node) do
    case Node.ping(:"#{conn_node}") do
      :pang -> false
      :pong -> true
    end
  end

  def set_interval(msg, ms) do
    # to handle_info/2
    Process.send_after(self(), msg, ms)
  end
end
