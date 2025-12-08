defmodule OsfBridge.UdpListener do
  use GenServer
  require Logger
  alias OsfBridge.OsfParser

  @default_port 12000
  @pubsub_topic "osf_bridge:packets"

  def start_link(opts \\ []) do
    port = Keyword.get(opts, :port, @default_port)
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  def init(port) do
    opts = [:binary, active: true, reuseaddr: true]
    case :gen_udp.open(port, opts) do
      {:ok, socket} ->
        Logger.info("UDP listener bound to port #{port}")
        {:ok, %{socket: socket, port: port}}
      {:error, reason} ->
        Logger.error("Failed to bind UDP port #{port}: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  def handle_info({:udp, _socket, ip, remote_port, packet}, state) do
    # IO.puts inspect(packet)
    parsed = OsfParser.parse(packet)

    # Logger.info("parsed packet: #{inspect(parsed)}")

    Phoenix.PubSub.broadcast(OsfBridge.PubSub, @pubsub_topic, {:osf_packet, parsed})

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.debug("Unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end
end
