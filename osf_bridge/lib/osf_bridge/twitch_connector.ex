defmodule OsfBridge.TwitchConnector do
  use GenServer

  require Logger

  @retry_ms 5_000

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    {:ok, nil, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, _socket_pid), do: connect()

  @impl true
  def handle_info(:connect, _socket_pid), do: connect()

  def handle_info({:DOWN, _reference, :process, socket_pid, reason}, socket_pid) do
    Logger.warning("Twitch EventSub process stopped: #{inspect(reason)}; retrying in 5 seconds")
    schedule_retry()
    {:noreply, nil}
  end

  def handle_info(_message, socket_pid), do: {:noreply, socket_pid}

  @impl true
  def terminate(_reason, socket_pid) when is_pid(socket_pid) do
    Process.exit(socket_pid, :shutdown)
  end

  def terminate(_reason, _socket_pid), do: :ok

  defp connect do
    Logger.info("Connecting to Twitch EventSub WebSocket")

    case OsfBridge.WebSocket.start([]) do
      {:ok, socket_pid} ->
        Process.monitor(socket_pid)
        {:noreply, socket_pid}

      {:error, reason} ->
        Logger.error(
          "Could not connect to Twitch EventSub: #{inspect(reason)}; retrying in 5 seconds"
        )

        schedule_retry()
        {:noreply, nil}
    end
  end

  defp schedule_retry do
    Process.send_after(self(), :connect, @retry_ms)
  end
end
