defmodule OsfBridgeWeb.OSFChannel do
  use OsfBridgeWeb, :channel

  @impl true
  def join("osf", _payload, socket) do
    Phoenix.PubSub.subscribe(OsfBridge.PubSub, "osf_bridge:packets")
    Phoenix.PubSub.subscribe(OsfBridge.PubSub, "osf_bridge:twitch_redeem")
    {:ok, socket}
  end

  @impl true
  def handle_info({:osf_packet, parsed}, socket) do
    push(socket, "packet", parsed)
    {:noreply, socket}
  end

  def handle_info({:twitch_redeem, payload}, socket) do
    if good_beverage_redeem?(payload) do
      push(socket, "good_beverage", %{"status" => "ok"})
    end

    {:noreply, socket}
  end

  defp good_beverage_redeem?(%{"reward" => reward}) when is_map(reward) do
    case Application.get_env(:osf_bridge, :good_beverage_reward_id) do
      reward_id when is_binary(reward_id) and reward_id != "" ->
        reward["id"] == reward_id

      _other ->
        configured_title =
          Application.get_env(:osf_bridge, :good_beverage_reward_title, "Good Beverage")

        normalize_reward_title(reward["title"]) == normalize_reward_title(configured_title)
    end
  end

  defp good_beverage_redeem?(_payload), do: false

  defp normalize_reward_title(title) when is_binary(title) do
    title
    |> String.trim()
    |> String.downcase()
  end

  defp normalize_reward_title(_title), do: nil

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
