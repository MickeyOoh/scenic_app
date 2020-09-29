defmodule Connect_Node do
  use GenServer
  require Logger

  @interval_init_ms 1_000
  @interval_wakeup_ms 1_000
  @interval_alive_ms 60_000
  @interval_alive_false_ms 1_000
  @get_by_connection ["interface", "wlan0", "connection"]
  # :disconnected  -->  :internet  then connected
  @get_by_addresses    ["interface", "wlan0", "addresses"]
  #[ {  ["interface", "wlan0", "addresses"],
  #     [  %{ address: {8193, 616, 49277, 8399, 47655, 60415, 65123, 45922},
  #           family: :inet6,
  #           netmask: {65535, 65535, 65535, 65535, 0, 0, 0, 0},
  #           prefix_length: 64,
  #           scope: :universe },
  #        %{ address: {192, 168, 100, 151},
  #          family: :inet,
  #          netmask: {255, 255, 255, 0},
  #          prefix_length: 24,
  #          scope: :universe },
  #        %{ address: {65152, 0, 0, 0, 47655, 60415, 65123, 45922},
  #          family: :inet6,
  #          netmask: {65535, 65535, 65535, 65535, 0, 0, 0, 0},
  #          prefix_length: 64,
  #          scope: :link  }  ]
  # } ]
  @node_name "node1"
  @node_cookie "chocolatechip"
  #@default_node ["rasppi@nerves.local", "chocolatechip", "master@mickeyoh.local"]

  def start_link(node_option \\ []) do
    GenServer.start_link(__MODULE__, node_option, name: __MODULE__)
  end

  def init(_node_option) do
    # get node domain from config
    [:hostname, node_domain] = Application.get_env(:mdns_lite, :host)
    node_domain = node_domain <> ".local"     # #{domain}.local
    state = %{
      address: nil,                     # ip address
      node_domain: node_domain,         # domain name
      node_name: "#{@node_name}@#{node_domain}",# node name
      node_cookie: @node_cookie,        #
      conn_nodes: [{"master@mickeyoh.local", false}],
    }
    # when connection changes, it receive msg from Vintage
    VintageNet.subscribe(@get_by_connection)
    # in case of net wake up already before the abvoe subscribe, the following steps are needed
    state = init_nodeconn(get_connection(), state)

    {:ok, state}
  end
  # connection status changes then receive msg as a new status
  def handle_info({VintageNet, @get_by_connection, _old, new_value, _}, state) do
    state = init_nodeconn(new_value, state)   # start up the node
    {:noreply, state}
  end

  def handle_info(:init, state) do
    state = init_nodeconn(get_connection(), state)
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
    ipadd = get_address()
    System.cmd("epmd", ["-daemon"])

    Node.start(:"#{node_name}")
    Node.set_cookie(:"#{cookie}")

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
    %{state | address: ipadd}
  end

  defp init_nodeconn(msg, state) do
    Logger.info("=== init_nodeconn -> #{inspect(msg)} ===")
    #set_interval(:init, @interval_init_ms)
    state
  end
  
  # connecting nodes
  defp nodeconn(%{conn_nodes: nodes} = state) do
    conns = Enum.map(nodes, fn {node, _} -> {node, Node.connect(:"#{node}")} end)
    ##Logger.info("=== Node.connect -> try connect to #{conn_node} ===")
    
    case Enum.all?(conns, fn {node, sts} -> sts == true end) do
      true ->
        Logger.info("=== nodeconn -> #{inspect conns} ===")
        set_interval(:alive, @interval_alive_ms)

      _ ->
        Logger.info("=== nodeconn -> #{inspect conns} ===")
        set_interval(:wakeup, @interval_wakeup_ms)
    end
  end

  defp re_nodeconn(:node_alive, _) do
    set_interval(:alive, @interval_alive_ms)
  end

  defp re_nodeconn(:node_re_conn, %{conn_nodes: nodes} = state) do
    conns = Enum.map(nodes, fn {node, _} -> {node, Node.connect(:"#{node}")} end)
    #Logger.info("=== re_nodeconn Node.connect -> #{conn_node} ===")

    case Enum.all?(conns, fn {node, sts} -> sts == true end) do
      true ->
        Logger.info("=== re_nodeconn -> #{inspect conns} ===")
        set_interval(:alive, @interval_alive_ms)

      _ ->
        Logger.info("=== re_nodeconn -> #{inspect conns} ===")        
        set_interval(:alive, @interval_alive_false_ms)
    end
  end

  defp re_nodeconn(:node_down, %{conn_nodes: nodes} = state) do
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

  def conn_node_alive?(%{conn_nodes: nodes} = state) do
    
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

  # def wlan0_ready?() do
  #   case get_ipaddr_wlan0() do
  #     nil -> false
  #     _ -> true
  #   end
  # end
  defp get_address() do
    [{_, addresses }] = VintageNet.get_by_prefix(@get_by_addresses)
    ipadd = Enum.find(addresses, nil, fn ipmap -> ipmap.family == :inet end)
    case ipadd do
      nil -> nil
      ipadd -> VintageNet.IP.ip_to_string(ipadd.address)
    end
 end
  defp get_connection() do
    [{@get_by_connection , connection}] = VintageNet.get_by_prefix(@get_by_connection)
    connection
  end
  # def get_ipaddr_wlan0(ipmaps) do
  #   ipadd = Enum.find(ipmaps, nil, fn ipmap -> ipmap.family == :inet end)
  #   case ipadd do
  #     nil -> nil
  #     ipadd -> VintageNet.IP.ip_to_string(ipadd.address)
  #   end
  # end

  def set_interval(msg, ms) do
    # to handle_info/2
    Process.send_after(self(), msg, ms)
  end
end
