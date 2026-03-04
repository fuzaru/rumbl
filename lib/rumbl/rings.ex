defmodule Rumbl.Rings do
  @moduledoc """
  The Rings context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Rumbl.Accounts.User
  alias Rumbl.Repo
  alias Rumbl.Rings.{Membership, Ring, RingInvitation}

  def list_user_rings(%User{id: user_id}) do
    from(r in Ring,
      join: membership in Membership,
      on: membership.ring_id == r.id and membership.user_id == ^user_id,
      left_join: member_count in Membership,
      on: member_count.ring_id == r.id,
      group_by: [r.id, r.name, r.invite_code, r.owner_id, r.inserted_at],
      order_by: [desc: r.inserted_at],
      select: %{
        id: r.id,
        name: r.name,
        invite_code: r.invite_code,
        owner_id: r.owner_id,
        status: "Active",
        members: count(member_count.id)
      }
    )
    |> Repo.all()
  end

  def ring_options_for_user(%User{} = user) do
    user
    |> list_user_rings()
    |> Enum.map(&{&1.name, &1.id})
  end

  def create_ring(%User{} = owner, attrs) do
    invite_code = generate_invite_code()

    Multi.new()
    |> Multi.insert(
      :ring,
      Ring.changeset(%Ring{owner_id: owner.id}, %{
        "name" => Map.get(attrs, "name", ""),
        "invite_code" => invite_code
      })
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
      {:ok, %{ring: ring}} ->
        {:ok, ring}

      {:error, :ring, changeset, _changes} ->
        {:error, changeset}

      {:error, :membership, changeset, _changes} ->
        {:error, changeset}
    end
  end

  def join_ring_by_invite(%User{} = user, invite_code) do
    code = invite_code |> to_string() |> String.trim() |> String.upcase()

    with %Ring{} = ring <- Repo.get_by(Ring, invite_code: code),
         false <- member?(ring.id, user.id) do
      Membership.changeset(%Membership{}, %{
        "ring_id" => ring.id,
        "user_id" => user.id,
        "role" => "member"
      })
      |> Repo.insert()
      |> case do
        {:ok, _membership} -> {:ok, ring}
        {:error, changeset} -> {:error, changeset}
      end
    else
      nil ->
        {:error, :invalid_code}

      true ->
        {:error, :already_member}
    end
  end

  def change_ring(%Ring{} = ring, attrs \\ %{}) do
    Ring.changeset(ring, attrs)
  end

  def list_owned_rings(%User{id: user_id}) do
    from(r in Ring, where: r.owner_id == ^user_id, order_by: [asc: r.name])
    |> Repo.all()
  end

  def list_invitation_requests(%User{id: user_id}) do
    from(inv in RingInvitation,
      where: inv.invitee_id == ^user_id and inv.status == "pending",
      preload: [:ring, :inviter],
      order_by: [desc: inv.inserted_at]
    )
    |> Repo.all()
  end

  def list_pending_invites_for_ring(ring_id) when is_binary(ring_id) do
    from(inv in RingInvitation,
      where: inv.ring_id == ^ring_id and inv.status == "pending"
    )
    |> Repo.all()
  end

  def send_ring_invitation(%User{} = inviter, ring_id, invitee_id)
      when is_binary(ring_id) and is_integer(invitee_id) do
    case Repo.get(Ring, ring_id) do
      nil ->
        {:error, :ring_not_found}

      %Ring{} = ring ->
        cond do
          ring.owner_id != inviter.id ->
            {:error, :not_allowed}

          invitee_id == inviter.id ->
            {:error, :cannot_invite_self}

          member?(ring_id, invitee_id) ->
            {:error, :already_member}

          pending_invite_exists?(ring_id, invitee_id) ->
            {:error, :already_invited}

          true ->
            RingInvitation.changeset(%RingInvitation{}, %{
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
      %RingInvitation{invitee_id: invitee_id, status: "pending"} = invitation
      when invitee_id == invitee.id ->
        apply_invitation_action(invitation, action)

      _ ->
        {:error, :not_found}
    end
  end

  def list_ring_members(ring_id) when is_binary(ring_id) do
    from(m in Membership,
      where: m.ring_id == ^ring_id,
      join: u in assoc(m, :user),
      order_by: [asc: u.username],
      select: %{
        id: u.id,
        name: u.name,
        username: u.username,
        role: m.role
      }
    )
    |> Repo.all()
  end

  defp member?(ring_id, user_id) do
    from(m in Membership, where: m.ring_id == ^ring_id and m.user_id == ^user_id)
    |> Repo.exists?()
  end

  defp pending_invite_exists?(ring_id, invitee_id) do
    from(inv in RingInvitation,
      where: inv.ring_id == ^ring_id and inv.invitee_id == ^invitee_id and inv.status == "pending"
    )
    |> Repo.exists?()
  end

  defp apply_invitation_action(invitation, "decline") do
    invitation
    |> RingInvitation.changeset(%{"status" => "declined"})
    |> Repo.update()
  end

  defp apply_invitation_action(invitation, "accept") do
    Multi.new()
    |> Multi.update(:invitation, RingInvitation.changeset(invitation, %{"status" => "accepted"}))
    |> Multi.run(:membership, fn repo, _changes ->
      if member?(invitation.ring_id, invitation.invitee_id) do
        {:ok, :already_member}
      else
        Membership.changeset(%Membership{}, %{
          "ring_id" => invitation.ring_id,
          "user_id" => invitation.invitee_id,
          "role" => "member"
        })
        |> repo.insert()
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{invitation: updated}} -> {:ok, updated}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  defp generate_invite_code do
    code =
      1..8
      |> Enum.map(fn _ -> Enum.random(~c"ABCDEFGHJKLMNPQRSTUVWXYZ23456789") end)
      |> List.to_string()

    if Repo.exists?(from(r in Ring, where: r.invite_code == ^code)) do
      generate_invite_code()
    else
      code
    end
  end
end
