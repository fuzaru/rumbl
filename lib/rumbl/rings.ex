defmodule Rumbl.Rings do
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Rumbl.Accounts.User
  alias Rumbl.Repo
  alias Rumbl.Rings.{Membership, Ring, RingInvitation}

  # Computed once at compile time; omits visually ambiguous chars (0/O, 1/I)
  @invite_alphabet ~c"ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

  def list_user_rings(%User{id: user_id}) do
    from(r in Ring,
      join: m in Membership,
      on: m.ring_id == r.id and m.user_id == ^user_id,
      left_join: mc in Membership,
      on: mc.ring_id == r.id,
      group_by: [r.id, r.name, r.invite_code, r.owner_id, r.inserted_at],
      order_by: [desc: r.inserted_at],
      select: %{
        id: r.id,
        name: r.name,
        invite_code: r.invite_code,
        owner_id: r.owner_id,
        status: "Active",
        members: count(mc.id)
      }
    )
    |> Repo.all()
  end

  def ring_options(rings) when is_list(rings), do: Enum.map(rings, &{&1.name, &1.id})

  def create_ring(%User{} = owner, attrs) do
    Multi.new()
    |> Multi.insert(
      :ring,
      Ring.changeset(
        %Ring{owner_id: owner.id},
        Map.put(attrs, "invite_code", generate_invite_code())
      )
    )
    |> Multi.insert(:membership, fn %{ring: ring} ->
      Membership.changeset(%Membership{}, %{
        "ring_id" => ring.id,
        "user_id" => owner.id,
        "role" => "owner"
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{ring: ring}} -> {:ok, ring}
      {:error, _step, changeset, _} -> {:error, changeset}
    end
  end

  def join_ring_by_invite(%User{} = user, invite_code) do
    code = invite_code |> to_string() |> String.trim() |> String.upcase()

    with %Ring{} = ring <- Repo.get_by(Ring, invite_code: code),
         false <- member?(ring.id, user.id),
         {:ok, _} <-
           %Membership{}
           |> Membership.changeset(%{
             "ring_id" => ring.id,
             "user_id" => user.id,
             "role" => "member"
           })
           |> Repo.insert() do
      {:ok, ring}
    else
      nil -> {:error, :invalid_code}
      true -> {:error, :already_member}
      error -> error
    end
  end

  def change_ring(%Ring{} = ring, attrs \\ %{}), do: Ring.changeset(ring, attrs)

  def list_owned_rings(%User{id: user_id}),
    do: Repo.all(from r in Ring, where: r.owner_id == ^user_id, order_by: [asc: r.name])

  def list_invitation_requests(%User{id: user_id}),
    do:
      Repo.all(
        from inv in RingInvitation,
          where: inv.invitee_id == ^user_id and inv.status == "pending",
          preload: [:ring, :inviter],
          order_by: [desc: inv.inserted_at]
      )

  def delete_owned_ring(%User{id: user_id}, ring_id) when is_binary(ring_id) do
    case Repo.get(Ring, ring_id) do
      nil -> {:error, :not_found}
      %Ring{owner_id: ^user_id} = ring -> Repo.delete(ring)
      %Ring{} -> {:error, :forbidden}
    end
  end

  def list_pending_invites_for_ring(ring_id) when is_binary(ring_id),
    do:
      Repo.all(
        from inv in RingInvitation, where: inv.ring_id == ^ring_id and inv.status == "pending"
      )

  def send_ring_invitation(%User{} = inviter, ring_id, invitee_id)
      when is_binary(ring_id) and is_integer(invitee_id) do
    case Repo.get(Ring, ring_id) do
      nil ->
        {:error, :ring_not_found}

      %Ring{owner_id: owner_id} when owner_id != inviter.id ->
        {:error, :not_allowed}

      %Ring{} when invitee_id == inviter.id ->
        {:error, :cannot_invite_self}

      %Ring{} ->
        cond do
          member?(ring_id, invitee_id) ->
            {:error, :already_member}

          pending_invite_exists?(ring_id, invitee_id) ->
            {:error, :already_invited}

          true ->
            %RingInvitation{}
            |> RingInvitation.changeset(%{
              "ring_id" => ring_id,
              "inviter_id" => inviter.id,
              "invitee_id" => invitee_id,
              "status" => "pending"
            })
            |> Repo.insert()
        end
    end
  end

  def respond_to_ring_invitation(%User{} = invitee, invitation_id, action)
      when is_binary(invitation_id) and action in ["accept", "decline"] do
    case Repo.get(RingInvitation, invitation_id) do
      %RingInvitation{invitee_id: invitee_id, status: "pending"} = inv
      when invitee_id == invitee.id ->
        apply_invitation_action(inv, action)

      _ ->
        {:error, :not_found}
    end
  end

  def list_ring_members(ring_id) when is_binary(ring_id),
    do:
      Repo.all(
        from m in Membership,
          where: m.ring_id == ^ring_id,
          join: u in assoc(m, :user),
          order_by: [asc: u.username],
          select: %{id: u.id, name: u.name, username: u.username, role: m.role}
      )

  def list_ring_peer_users(%User{id: user_id}),
    do:
      Repo.all(
        from u in User,
          join: cm in Membership,
          on: cm.user_id == ^user_id,
          join: pm in Membership,
          on: pm.ring_id == cm.ring_id and pm.user_id == u.id,
          where: u.id != ^user_id,
          distinct: u.id,
          order_by: [asc: u.username]
      )

  def share_ring?(%User{id: id}, %User{id: id}), do: true

  def share_ring?(%User{id: l}, %User{id: r}),
    do:
      Repo.exists?(
        from lm in Membership,
          join: rm in Membership,
          on: rm.ring_id == lm.ring_id,
          where: lm.user_id == ^l and rm.user_id == ^r
      )

  defp member?(ring_id, user_id),
    do: Repo.exists?(from m in Membership, where: m.ring_id == ^ring_id and m.user_id == ^user_id)

  defp pending_invite_exists?(ring_id, invitee_id),
    do:
      Repo.exists?(
        from inv in RingInvitation,
          where:
            inv.ring_id == ^ring_id and inv.invitee_id == ^invitee_id and inv.status == "pending"
      )

  defp apply_invitation_action(invitation, "decline"),
    do: invitation |> RingInvitation.changeset(%{"status" => "declined"}) |> Repo.update()

  defp apply_invitation_action(invitation, "accept") do
    Multi.new()
    |> Multi.update(:invitation, RingInvitation.changeset(invitation, %{"status" => "accepted"}))
    |> Multi.run(:membership, fn repo, _ ->
      if member?(invitation.ring_id, invitation.invitee_id),
        do: {:ok, :already_member},
        else:
          %Membership{}
          |> Membership.changeset(%{
            "ring_id" => invitation.ring_id,
            "user_id" => invitation.invitee_id,
            "role" => "member"
          })
          |> repo.insert()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{invitation: updated}} -> {:ok, updated}
      {:error, _step, reason, _} -> {:error, reason}
    end
  end

  # Retry on (vanishingly rare) collision
  defp generate_invite_code do
    code = for(_ <- 1..8, into: "", do: <<Enum.random(@invite_alphabet)>>)

    if Repo.exists?(from r in Ring, where: r.invite_code == ^code),
      do: generate_invite_code(),
      else: code
  end
end
