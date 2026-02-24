defmodule RumblWeb.UserLiveAuth do
  @moduledoc """
  LiveView authentication helpers.
  """

  import Phoenix.Component, only: [assign_new: 3]
  import Phoenix.LiveView

  alias Rumbl.Accounts

  def on_mount(:mount_current_user, _params, session, socket) do
    socket =
      socket
      |> assign_new(:current_scope, fn -> nil end)
      |> assign_new(:current_user, fn -> get_user_from_session(session) end)

    {:cont, socket}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket =
      socket
      |> assign_new(:current_scope, fn -> nil end)
      |> assign_new(:current_user, fn -> get_user_from_session(session) end)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt,
       socket
       |> put_flash(:error, "You must be logged in to access this page")
       |> redirect(to: "/sessions/new")}
    end
  end

  defp get_user_from_session(%{"user_id" => user_id}), do: Accounts.get_user(user_id)
  defp get_user_from_session(_session), do: nil
end
