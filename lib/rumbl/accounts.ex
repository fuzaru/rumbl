defmodule Rumbl.Accounts do
  import Ecto.Query, warn: false
  alias Rumbl.Repo
  alias Rumbl.Accounts.User

  def get_user(id), do: Repo.get(User, id)
  def get_user!(id), do: Repo.get!(User, id)
  def get_user_by(attrs), do: Repo.get_by(User, attrs)

  def search_users(query, opts \\ []) do
    case query |> to_string() |> String.trim() do
      "" ->
        []

      term ->
        excluded_ids = Keyword.get(opts, :exclude_ids, [])
        pattern = "%#{term}%"

        q =
          from(u in User,
            where: ilike(u.username, ^pattern) or ilike(u.name, ^pattern),
            order_by: [asc: u.username],
            limit: ^Keyword.get(opts, :limit, 8)
          )

        q =
          if excluded_ids == [],
            do: q,
            else: from(u in q, where: u.id not in ^excluded_ids)

        Repo.all(q)
    end
  end

  def list_users_by_ids([]), do: []

  def list_users_by_ids(ids) when is_list(ids),
    do: Repo.all(from u in User, where: u.id in ^ids)

  def register_user(attrs \\ %{}),
    do: %User{} |> User.registration_changeset(attrs) |> Repo.insert()

  def update_user(%User{} = user, attrs),
    do: user |> User.changeset(attrs) |> Repo.update()

  def delete_user(%User{} = user), do: Repo.delete(user)

  def change_user(%User{} = user, attrs \\ %{}), do: User.changeset(user, attrs)

  def change_registration(%User{} = user, attrs \\ %{}),
    do: User.registration_changeset(user, attrs)

  def authenticate_by_username_and_pass(username, given_pass) do
    user = get_user_by(username: username)

    cond do
      user && Bcrypt.verify_pass(given_pass, user.password_hash) ->
        {:ok, user}

      user ->
        {:error, :unauthorized}

      true ->
        # Prevent timing attacks
        Bcrypt.no_user_verify()
        {:error, :not_found}
    end
  end
end
