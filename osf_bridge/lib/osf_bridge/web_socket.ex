defmodule OsfBridge.WebSocket do
  use WebSockex

  require Logger

  @event_type "channel.channel_points_custom_reward_redemption.add"
  @pubsub_topic "osf_bridge:twitch_redeem"
  @url "wss://eventsub.wss.twitch.tv/ws"

  def start_link(state) do
    Logger.info("Connecting to Twitch EventSub WebSocket")
    WebSockex.start_link(@url, __MODULE__, state, name: __MODULE__)
  end

  def start(state) do
    WebSockex.start(@url, __MODULE__, state, name: __MODULE__)
  end

  @impl true
  def handle_connect(_conn, state) do
    Logger.info("Connected to Twitch EventSub; waiting for session welcome")
    {:ok, state}
  end

  @impl true
  def handle_disconnect(disconnect_map, state) do
    Logger.warning("Disconnected from Twitch EventSub: #{inspect(disconnect_map)}")
    {:reconnect, state}
  end

  @impl true
  def handle_frame({:text, message}, state) do
    case Jason.decode(message) do
      {:ok, payload} ->
        handle_message(payload)

      {:error, error} ->
        Logger.warning("Could not decode Twitch EventSub message: #{inspect(error)}")
    end

    {:ok, state}
  end

  def handle_frame({_type, _message}, state), do: {:ok, state}

  defp handle_message(%{
         "metadata" => %{"message_type" => "session_welcome"},
         "payload" => %{"session" => %{"id" => session_id}}
       }) do
    Logger.info("Twitch EventSub session established; creating channel-points subscription")
    subscribe(session_id)
  end

  defp handle_message(%{
         "metadata" => %{
           "message_type" => "notification",
           "subscription_type" => @event_type
         },
         "payload" => %{"event" => event}
       }) do
    reward = event["reward"] || %{}

    Logger.info(
      "Received Twitch redemption: reward_title=#{inspect(reward["title"])} " <>
        "reward_id=#{inspect(reward["id"])} user=#{inspect(event["user_login"])}"
    )

    Phoenix.PubSub.broadcast(
      OsfBridge.PubSub,
      @pubsub_topic,
      {:twitch_redeem, event}
    )
  end

  defp handle_message(%{"metadata" => %{"message_type" => "session_keepalive"}}), do: :ok

  defp handle_message(%{"metadata" => %{"message_type" => message_type}}) do
    Logger.debug("Received Twitch EventSub message: #{message_type}")
  end

  defp handle_message(message) do
    Logger.debug("Received unrecognized Twitch EventSub message: #{inspect(message)}")
  end

  defp subscribe(session_id) do
    client_id = System.get_env("TWITCH_CLIENT_ID")
    oauth_token = System.get_env("TWITCH_OAUTH_TOKEN")
    broadcaster_id = System.get_env("TWITCH_BROADCASTER_ID")

    missing =
      [
        {"TWITCH_CLIENT_ID", client_id},
        {"TWITCH_OAUTH_TOKEN", oauth_token},
        {"TWITCH_BROADCASTER_ID", broadcaster_id}
      ]
      |> Enum.filter(fn {_name, value} -> is_nil(value) or value == "" end)
      |> Enum.map_join(", ", &elem(&1, 0))

    if missing == "" do
      create_subscription(session_id, client_id, oauth_token, broadcaster_id)
    else
      Logger.error(
        "Cannot subscribe to Twitch EventSub; missing environment variables: #{missing}"
      )
    end
  end

  defp create_subscription(session_id, client_id, oauth_token, broadcaster_id) do
    body = %{
      type: @event_type,
      version: "1",
      condition: %{broadcaster_user_id: broadcaster_id},
      transport: %{method: "websocket", session_id: session_id}
    }

    headers = [
      {"authorization", "Bearer #{oauth_token}"},
      {"client-id", client_id}
    ]

    case Req.post("https://api.twitch.tv/helix/eventsub/subscriptions",
           json: body,
           headers: headers
         ) do
      {:ok, %Req.Response{status: status}} when status in 200..299 ->
        Logger.info("Twitch channel-points subscription created successfully (HTTP #{status})")

      {:ok, %Req.Response{status: status, body: response_body}} ->
        Logger.error(
          "Twitch rejected the channel-points subscription (HTTP #{status}): #{inspect(response_body)}"
        )

      {:error, error} ->
        Logger.error("Twitch subscription request failed: #{Exception.message(error)}")
    end
  end
end
