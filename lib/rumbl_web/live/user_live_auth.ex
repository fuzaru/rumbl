defmodule RumblWeb.UserLiveAuth do
  @moduledoc """
  LiveView authentication helpers.
  """

  import Phoenix.Component, only: [assign_new: 3]
  import Phoenix.LiveView

  alias Rumbl.Accounts
  alias RumblWeb.Locale

  def on_mount(:mount_current_user, _params, session, socket) do
    locale = Locale.from_session(session)
    Gettext.put_locale(RumblWeb.Gettext, locale)

    socket = assign_session_context(socket, session, locale)

    {:cont, socket}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    locale = Locale.from_session(session)
    Gettext.put_locale(RumblWeb.Gettext, locale)

    socket = assign_session_context(socket, session, locale)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt,
       socket
       |> put_flash(:error, "You must be logged in to access this page")
       |> redirect(to: "/sessions/new")}
    end
  end

  defp assign_session_context(socket, session, locale) do
    socket
    |> assign_new(:locale, fn -> locale end)
    |> assign_new(:current_scope, fn -> nil end)
    |> assign_new(:current_user, fn ->
      case session do
        %{"user_id" => id} -> Accounts.get_user(id)
        _ -> nil
      end
    end)
  end
end
