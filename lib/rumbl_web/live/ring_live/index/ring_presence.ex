defmodule RumblWeb.RingLive.Index.RingPresence do
  import Phoenix.Component, only: [assign: 3]

  alias Rumbl.Accounts
  alias Rumbl.Rings
  alias RumblWeb.Presence

  def refresh_ring_members(socket) do
    members =
      if ring = socket.assigns.selected_ring, do: Rings.list_ring_members(ring.id), else: []

    assign(socket, :ring_members, members)
  end

  def sync_presence_topic(socket) do
    ring = socket.assigns.selected_ring
    previous_tracked_topic = socket.assigns.presence_topic
    next_tracked_topic = if ring, do: ring_presence_topic(ring.id), else: nil

    desired_subscriptions =
      if ring do
        MapSet.new([next_tracked_topic])
      else
        socket.assigns.rings |> Enum.map(&ring_presence_topic(&1.id)) |> MapSet.new()
      end

    socket =
      if Phoenix.LiveView.connected?(socket) do
        current_subs = socket.assigns.presence_subscriptions

        current_subs
        |> MapSet.difference(desired_subscriptions)
        |> Enum.each(&Phoenix.PubSub.unsubscribe(Rumbl.PubSub, &1))

        desired_subscriptions
        |> MapSet.difference(current_subs)
        |> Enum.each(&Phoenix.PubSub.subscribe(Rumbl.PubSub, &1))

        key = presence_key(socket.assigns.current_user.id)

        if previous_tracked_topic && previous_tracked_topic != next_tracked_topic do
          Presence.untrack(self(), previous_tracked_topic, key)
        end

        if next_tracked_topic && previous_tracked_topic != next_tracked_topic do
          {:ok, _} =
            Presence.track(self(), next_tracked_topic, key, %{
              online_at: System.system_time(:second)
            })
        end

        socket
      else
        socket
      end

    online_ids =
      if next_tracked_topic, do: online_member_ids(next_tracked_topic), else: MapSet.new()

    active_ring_users =
      if ring, do: [], else: active_users_for_rings(socket.assigns.rings)

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
    ring_names = Map.new(rings, &{&1.id, &1.name})

    ring_membership =
      Enum.reduce(rings, %{}, fn ring, acc ->
        ring_name = Map.fetch!(ring_names, ring.id)

        Enum.reduce(Presence.list(ring_presence_topic(ring.id)), acc, fn {key, _}, user_acc ->
          case parse_presence_key(key) do
            {:ok, uid} ->
              Map.update(user_acc, uid, MapSet.new([ring_name]), &MapSet.put(&1, ring_name))

            :error ->
              user_acc
          end
        end)
      end)

    users_by_id =
      ring_membership
      |> Map.keys()
      |> Accounts.list_users_by_ids()
      |> Map.new(&{&1.id, &1})

    ring_membership
    |> Enum.flat_map(fn {uid, user_rings} ->
      case Map.get(users_by_id, uid) do
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
    for {key, _} <- Presence.list(topic),
        {:ok, uid} <- [parse_presence_key(key)],
        into: MapSet.new(),
        do: uid
  end

  defp parse_presence_key("user:" <> id) do
    case Integer.parse(id) do
      {uid, ""} -> {:ok, uid}
      _ -> :error
    end
  end

  defp parse_presence_key(_), do: :error

  defp presence_key(user_id), do: "user:#{user_id}"
  defp ring_presence_topic(ring_id), do: "ring_presence:#{ring_id}"
end
