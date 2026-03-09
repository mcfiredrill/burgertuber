defmodule OsfBridge.WebSocket do
  use WebSockex
  require Logger

  @pubsub_topic "osf_bridge:twitch_redeem"

  def start_link(state) do
    WebSockex.start_link(
      "wss://eventsub.wss.twitch.tv/ws",
      __MODULE__,
      state,
      name: __MODULE__
    )
  end

  # def handle_frame({type, msg}, state) do
  #   IO.puts "Received WS Message - Type: #{inspect type} -- Message: #{inspect msg}"
  #   # pull out session ID
  #   {:ok, json } = Jason.decode(msg)
  #   message_type = json["metadata"]["message_type"]
  #   case message_type do
  #     "session_welcome" ->
  #       session_id = json["payload"]["session"]["id"]
  #       # create subscriptions with it (POST)
  #       subscribe "channel.channel_points_custom_reward_redemption.add", session_id
  #       # subscribe "channel.follow", session_id
  #       # subscribe "channel.raid", session_id
  #       # TODO
  #       # subscribe "channel.subscribe", session_id
  #       # subscribe "channel.subscription.gift", session_id
  #       # subscribe "channel.cheer", session_id
  #       # subscribe "channel.channel_points_custom_reward_redemption.add", session_id
  #     "notification" ->
  #       Logger.debug "got a notification"
  #       subscription_type = json["metadata"]["subscription_type"]
  #       Logger.debug "subscription_type: #{subscription_type}"
  #       case subscription_type do
  #         "channel.channel_points_custom_reward_redemption.add" ->
  #           # TODO
  #           Phoenix.PubSub.broadcast(OsfBridge.PubSub, @pubsub_topic, {:twitch_redeem, json["payload"]["event"]})
  #         # "channel.follow" ->
  #         #   notify_new_follower json["payload"]["event"]
  #         # "channel.raid" ->
  #         #   notify_raid json["payload"]["event"]
  #         _ ->
  #           Logger.debug "no handler for notification type: #{subscription_type}"
  #       end
  #     _ ->
  #       Logger.debug "unknown websocket message type: #{message_type}"
  #   end
  #   {:ok, state}
  # end
  #
  # def handle_cast({:send, {type, msg} = frame}, state) do
  #   IO.puts "Sending #{type} frame with payload: #{msg}"
  #   {:reply, frame, state}
  # end
  #
  # defp subscribe(event_type, session_id) do
  #   url = "https://api.twitch.tv/helix/eventsub/subscriptions"
  #   version = event_version(event_type)
  #   condition = event_condition(event_type)
  #   text = %{
  #     type: event_type,
  #     version: version,
  #     condition: condition,
  #     transport: %{
  #       method: "websocket",
  #       session_id: session_id
  #     }
  #
  #   }
  #   {:ok, body } = Jason.encode(text)
  #   headers = [
  #     {"Authorization", "Bearer #{System.get_env("TWITCH_OAUTH_TOKEN")}"},
  #     {"Client-Id", System.get_env("TWITCH_CLIENT_ID")},
  #     {"Content-Type", "application/json"},
  #   ]
  #   {:ok, response } = HTTPoison.post url, body, headers
  #   Logger.debug(inspect response)
  # end
  #
  # defp event_version(event_type) do
  #   case event_type do
  #     "channel.follow" ->
  #       2
  #     "channel.raid" ->
  #       1
  #     "channel.channel_points_custom_reward_redemption.add" ->
  #       1
  #     _ ->
  #       Logger.debug "unknown version for event type: #{event_type}"
  #   end
  # end
  #
  # defp event_condition(event_type) do
  #   case event_type do
  #     "channel.follow" ->
  #       %{
  #         broadcaster_user_id: System.get_env("TWITCH_BROADCASTER_ID"),
  #         moderator_user_id: System.get_env("TWITCH_BROADCASTER_ID")
  #       }
  #     "channel.raid" ->
  #       %{
  #         to_broadcaster_user_id: System.get_env("TWITCH_BROADCASTER_ID")
  #       }
  #     "channel.channel_points_custom_reward_redemption.add" ->
  #       %{
  #         broadcaster_user_id: System.get_env("TWITCH_BROADCASTER_ID")
  #       }
  #     _ ->
  #       Logger.debug "unknown condition for event type: #{event_type}"
  #   end
  # end
end
