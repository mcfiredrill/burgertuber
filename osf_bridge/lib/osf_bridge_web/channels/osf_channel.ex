defmodule OsfBridgeWeb.OSFChannel do
  use OsfBridgeWeb, :channel

  @impl true
  def join("osf", payload, socket) do
    Phoenix.PubSub.subscribe(OsfBridge.PubSub, "osf_bridge:packets")
    Phoenix.PubSub.subscribe(OsfBridge.PubSub, "osf_bridge:twitch_redeem")
    {:ok, socket}
  end

  def handle_info({:osf_packet, parsed}, socket) do
    push(socket, "packet", parsed)
    {:noreply, socket}
  end

  def handle_info({:twitch_redeem, payload}, socket) do
    # TODO check if redeem type is good_beverage throw
    push(socket, "good_beverage", "ok")
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
