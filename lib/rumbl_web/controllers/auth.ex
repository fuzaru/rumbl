defmodule RumblWeb.Auth do
  @moduledoc "Authentication plug for managing user sessions."

  import Plug.Conn
  import Phoenix.Controller

  alias Rumbl.Accounts

  def init(opts), do: opts

  # Already assigned (e.g., in tests) — skip DB hit
  def call(%{assigns: %{current_user: _}} = conn, _), do: conn

  def call(conn, _) do
    user =
      case get_session(conn, :user_id) do
        nil -> nil
        id -> Accounts.get_user(id)
      end

    assign(conn, :current_user, user)
  end

  def login(conn, user) do
    conn
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true)
    |> assign(:current_user, user)
  end

  def logout(conn), do: configure_session(conn, drop: true)

  def require_authenticated_user(conn, _) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access this page")
      |> redirect(to: "/sessions/new")
      |> halt()
    end
  end
end
