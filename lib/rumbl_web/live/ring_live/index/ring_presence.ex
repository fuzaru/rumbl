defmodule RumblWeb.RingLive.Index.RingPresence do
  import Phoenix.Component, only: [assign: 3]

  alias Rumbl.Accounts
  alias Rumbl.Rings
  alias RumblWeb.Presence

  def refresh_ring_members(socket) do
    ring = socket.assigns.selected_ring

    if ring do
      assign(socket, :ring_members, Rings.list_ring_members(ring.id))
    else
      assign(socket, :ring_members, [])
    end
  end

  def sync_presence_topic(socket) do
    ring = socket.assigns.selected_ring
    previous_tracked_topic = socket.assigns.presence_topic
    next_tracked_topic = if ring, do: ring_presence_topic(ring.id), else: nil

    desired_subscriptions =
      if ring do
        MapSet.new([next_tracked_topic])
      else
        socket.assigns.rings
        |> Enum.map(&ring_presence_topic(&1.id))
        |> MapSet.new()
      end

    current_subscriptions = socket.assigns.presence_subscriptions

    socket =
      if Phoenix.LiveView.connected?(socket) do
        subscriptions_to_remove = MapSet.difference(current_subscriptions, desired_subscriptions)
        subscriptions_to_add = MapSet.difference(desired_subscriptions, current_subscriptions)

        Enum.each(subscriptions_to_remove, fn topic ->
          Phoenix.PubSub.unsubscribe(Rumbl.PubSub, topic)
        end)

        Enum.each(subscriptions_to_add, fn topic ->
          Phoenix.PubSub.subscribe(Rumbl.PubSub, topic)
        end)

        if previous_tracked_topic && previous_tracked_topic != next_tracked_topic do
          Presence.untrack(
            self(),
            previous_tracked_topic,
            presence_key(socket.assigns.current_user.id)
          )
        end

        if next_tracked_topic && previous_tracked_topic != next_tracked_topic do
          {:ok, _meta} =
            Presence.track(
              self(),
              next_tracked_topic,
              presence_key(socket.assigns.current_user.id),
              %{online_at: System.system_time(:second)}
            )
        end

        socket
      else
        socket
      end

    online_ids =
      if next_tracked_topic, do: online_member_ids(next_tracked_topic), else: MapSet.new()

    active_ring_users =
      if ring do
        []
      else
        active_users_for_rings(socket.assigns.rings)
      end

    socket
    |> assign(:presence_topic, next_tracked_topic)
    |> assign(:presence_subscriptions, desired_subscriptions)
    |> assign(:online_member_ids, online_ids)
    |> assign(:active_ring_users, active_ring_users)
  end

  def handle_presence_diff(socket, topic) do
    socket =
      if topic == socket.assigns.presence_topic do
        assign(socket, :online_member_ids, online_member_ids(topic))
      else
        socket
      end

    if is_nil(socket.assigns.selected_ring) &&
         MapSet.member?(socket.assigns.presence_subscriptions, topic) do
      assign(socket, :active_ring_users, active_users_for_rings(socket.assigns.rings))
    else
      socket
    end
  end

  def topics_for_rings(rings) when is_list(rings) do
    rings
    |> Enum.map(&ring_presence_topic(&1.id))
    |> MapSet.new()
  end

  def active_users_for_rings(rings) when is_list(rings) do
    ring_names_by_id = Map.new(rings, fn ring -> {ring.id, ring.name} end)

    ring_membership_by_user_id =
      Enum.reduce(rings, %{}, fn ring, acc ->
        topic = ring_presence_topic(ring.id)
        ring_name = Map.fetch!(ring_names_by_id, ring.id)

        Presence.list(topic)
        |> Enum.reduce(acc, fn {key, _details}, user_acc ->
          case parse_presence_key(key) do
            {:ok, user_id} ->
              Map.update(user_acc, user_id, MapSet.new([ring_name]), &MapSet.put(&1, ring_name))

            :error ->
              user_acc
          end
        end)
      end)

    user_ids = Map.keys(ring_membership_by_user_id)

    users_by_id =
      Accounts.list_users_by_ids(user_ids)
      |> Map.new(fn user -> {user.id, user} end)

    ring_membership_by_user_id
    |> Enum.flat_map(fn {user_id, user_rings} ->
      case Map.get(users_by_id, user_id) do
        nil ->
          []

        user ->
          [
            %{
              id: user.id,
              name: user.name,
              username: user.username,
              rings: user_rings |> MapSet.to_list() |> Enum.sort()
            }
          ]
      end
    end)
    |> Enum.sort_by(& &1.username)
  end

  defp online_member_ids(topic) do
    Presence.list(topic)
    |> Enum.reduce(MapSet.new(), fn {key, _details}, acc ->
      case key do
        "user:" <> id ->
          case Integer.parse(id) do
            {user_id, ""} -> MapSet.put(acc, user_id)
            _ -> acc
          end

        _ ->
          acc
      end
    end)
  end

  defp parse_presence_key("user:" <> id) do
    case Integer.parse(id) do
      {user_id, ""} -> {:ok, user_id}
      _ -> :error
    end
  end

  defp parse_presence_key(_), do: :error

  defp presence_key(user_id), do: "user:#{user_id}"
  defp ring_presence_topic(ring_id), do: "ring_presence:#{ring_id}"
end
