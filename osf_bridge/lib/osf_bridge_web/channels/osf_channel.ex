defmodule OsfBridgeWeb.OSFChannel do
  use OsfBridgeWeb, :channel

  @impl true
  def join("osf", payload, socket) do
    Phoenix.PubSub.subscribe(OsfBridge.PubSub, "osf_bridge:packets")
    {:ok, socket}
  end

  def handle_info({:osf_packet, parsed}, socket) do
    push(socket, "packet", parsed)
    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (osf:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # # Add authorization logic here as required.
  # defp authorized?(_payload) do
  #   true
  # end
end
