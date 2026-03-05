defmodule RumblWeb.UserLive.Index do
  use RumblWeb, :live_view

  alias Rumbl.Rings

  @impl true
  def mount(_params, _session, socket) do
    users = list_directory_users(socket.assigns.current_user)
    rings = list_sidebar_rings(socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:page_title, "Users")
     |> assign(:rings, rings)
     |> assign(:users, users)
     |> assign(:search_form, to_form(%{"query" => ""}, as: :user_search))
     |> assign(:search_query, "")
     |> assign(:filtered_users, users)}
  end

  @impl true
  def handle_event("search_users", %{"user_search" => %{"query" => query}}, socket) do
    trimmed_query = String.trim(query)

    {:noreply,
     socket
     |> assign(:search_query, trimmed_query)
     |> assign(:search_form, to_form(%{"query" => trimmed_query}, as: :user_search))
     |> assign(:filtered_users, filter_users(socket.assigns.users, trimmed_query))}
  end

  defp list_sidebar_rings(nil), do: []
  defp list_sidebar_rings(current_user), do: Rings.list_user_rings(current_user)

  defp list_directory_users(nil) do
    []
  end

  defp list_directory_users(current_user) do
    Rings.list_ring_peer_users(current_user)
  end

  defp filter_users(users, ""), do: users

  defp filter_users(users, query) do
    normalized_query = String.downcase(query)

    Enum.filter(users, fn user ->
      String.contains?(String.downcase(user.name), normalized_query) or
        String.contains?(String.downcase(user.username), normalized_query)
    end)
  end
end
