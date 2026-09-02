defmodule OsfBridgeWeb.OSFChannelTest do
  use OsfBridgeWeb.ChannelCase

  setup do
    {:ok, _, socket} =
      OsfBridgeWeb.UserSocket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(OsfBridgeWeb.OSFChannel, "osf")

    %{socket: socket}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push(socket, "ping", %{"hello" => "there"})
    assert_reply ref, :ok, %{"hello" => "there"}
  end

  test "shout broadcasts to osf:lobby", %{socket: socket} do
    push(socket, "shout", %{"hello" => "all"})
    assert_broadcast "shout", %{"hello" => "all"}
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from!(socket, "broadcast", %{"some" => "data"})
    assert_push "broadcast", %{"some" => "data"}
  end

  test "a configured good beverage redeem is pushed to the client", %{socket: socket} do
    previous_reward_id = Application.get_env(:osf_bridge, :good_beverage_reward_id)
    Application.put_env(:osf_bridge, :good_beverage_reward_id, "good-beverage-id")

    on_exit(fn ->
      Application.put_env(:osf_bridge, :good_beverage_reward_id, previous_reward_id)
    end)

    send(socket.channel_pid, {
      :twitch_redeem,
      %{"reward" => %{"id" => "good-beverage-id", "title" => "Anything"}}
    })

    assert_push "good_beverage", %{"status" => "ok"}
  end

  test "an unrelated redeem is ignored", %{socket: socket} do
    previous_reward_id = Application.get_env(:osf_bridge, :good_beverage_reward_id)
    Application.put_env(:osf_bridge, :good_beverage_reward_id, "good-beverage-id")

    on_exit(fn ->
      Application.put_env(:osf_bridge, :good_beverage_reward_id, previous_reward_id)
    end)

    send(socket.channel_pid, {
      :twitch_redeem,
      %{"reward" => %{"id" => "hydrate-id", "title" => "Hydrate"}}
    })

    refute_push "good_beverage", _payload, 100
  end

  test "the reward title is used when no reward id is configured", %{socket: socket} do
    previous_reward_id = Application.get_env(:osf_bridge, :good_beverage_reward_id)
    previous_reward_title = Application.get_env(:osf_bridge, :good_beverage_reward_title)
    Application.delete_env(:osf_bridge, :good_beverage_reward_id)
    Application.put_env(:osf_bridge, :good_beverage_reward_title, "Good Beverage")

    on_exit(fn ->
      Application.put_env(:osf_bridge, :good_beverage_reward_id, previous_reward_id)
      Application.put_env(:osf_bridge, :good_beverage_reward_title, previous_reward_title)
    end)

    send(socket.channel_pid, {
      :twitch_redeem,
      %{"reward" => %{"id" => "some-id", "title" => " good beverage "}}
    })

    assert_push "good_beverage", %{"status" => "ok"}
  end
end
