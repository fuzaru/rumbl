defmodule Rumbl.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @username_format ~r/^[a-zA-Z0-9_]+$/

  schema "users" do
    field :name, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string

    has_many :videos, Rumbl.Multimedia.Video
    has_many :annotations, Rumbl.Multimedia.Annotation

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :username])
    |> validate_required([:name, :username])
    |> validate_length(:username, min: 3, max: 20)
    |> validate_format(:username, @username_format, message: "must be alphanumeric")
    |> unique_constraint(:username)
  end

  def registration_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 100)
    |> put_password_hash()
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = cs) do
    put_change(cs, :password_hash, Bcrypt.hash_pwd_salt(password))
  end

  defp put_password_hash(cs), do: cs
end
