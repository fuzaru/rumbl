defmodule Rumbl.Accounts do
  @moduledoc """
  The Accounts context - handles user operations.
  """

  import Ecto.Query, warn: false
  alias Rumbl.Repo
  alias Rumbl.Accounts.User

  @doc """
  Returns the list of users.
  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.
  Returns nil if not found.
  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Gets a single user.
  Raises if not found.
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a user by attributes.
  """
  def get_user_by(attrs) do
    Repo.get_by(User, attrs)
  end

  def search_users(query, opts \\ []) do
    term = query |> to_string() |> String.trim()

    if term == "" do
      []
    else
      excluded_ids = Keyword.get(opts, :exclude_ids, [])
      limit = Keyword.get(opts, :limit, 8)
      pattern = "%#{term}%"

      base_query =
        from(u in User,
          where: ilike(u.username, ^pattern) or ilike(u.name, ^pattern),
          order_by: [asc: u.username],
          limit: ^limit
        )

      base_query =
        if excluded_ids == [] do
          base_query
        else
          from(u in base_query, where: u.id not in ^excluded_ids)
        end

      base_query
      |> Repo.all()
    end
  end

  def list_users_by_ids(ids) when is_list(ids) do
    if ids == [] do
      []
    else
      from(u in User, where: u.id in ^ids)
      |> Repo.all()
    end
  end

  @doc """
  Registers a new user.
  """
  def register_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_user(%User{}) :: {:ok, %User{}} | {:error, Ecto.Changeset.t()}
  @doc """
  Deletes a user.
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Returns a registration changeset.
  """
  def change_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end

  @doc """
  Authenticates a user by username and password.
  """
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
