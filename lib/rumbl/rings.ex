defmodule Rumbl.Rings do
  @moduledoc """
  The Rings context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Rumbl.Accounts.User
  alias Rumbl.Repo
  alias Rumbl.Rings.{Membership, Ring}

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

  defp member?(ring_id, user_id) do
    from(m in Membership, where: m.ring_id == ^ring_id and m.user_id == ^user_id)
    |> Repo.exists?()
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
