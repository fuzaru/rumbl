defmodule Rumbl.Accounts do
  import Ecto.Query, warn: false
  alias Rumbl.Repo
  alias Rumbl.Accounts.User

  def get_user(id), do: Repo.get(User, id)
  def get_user!(id), do: Repo.get!(User, id)
  def get_user_by(attrs), do: Repo.get_by(User, attrs)

  def search_users(query, opts \\ []) do
    trimmed_query =
      query
      |> to_string()
      |> String.trim()

    if trimmed_query == "" do
      []
    else
      excluded_ids = Keyword.get(opts, :exclude_ids, [])
      pattern = "%#{trimmed_query}%"
      limit = Keyword.get(opts, :limit, 8)

      User
      |> where([u], ilike(u.username, ^pattern) or ilike(u.name, ^pattern))
      |> order_by([u], asc: u.username)
      |> limit(^limit)
      |> maybe_exclude_ids(excluded_ids)
      |> Repo.all()
    end
  end

  defp maybe_exclude_ids(query, []), do: query

  defp maybe_exclude_ids(query, excluded_ids) do
    where(query, [u], u.id not in ^excluded_ids)
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
        Bcrypt.no_user_verify()
        {:error, :not_found}
    end
  end
end
