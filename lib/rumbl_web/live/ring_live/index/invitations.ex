defmodule RumblWeb.RingLive.Index.Invitations do
  import Phoenix.Component, only: [assign: 3, to_form: 2]

  alias Rumbl.Accounts
  alias Rumbl.Rings
  alias RumblWeb.RingLive.Index.RingManagement

  def init_assigns(socket) do
    owned_rings = Rings.list_owned_rings(socket.assigns.current_user)
    selected_invite_ring_id = default_invite_ring_id(owned_rings)

    socket
    |> assign(:owned_rings, owned_rings)
    |> assign(:selected_invite_ring_id, selected_invite_ring_id)
    |> assign(:invite_search_results, [])
    |> assign(:invitation_requests, Rings.list_invitation_requests(socket.assigns.current_user))
    |> assign(
      :invite_ring_form,
      to_form(%{"ring_id" => selected_invite_ring_id || ""}, as: :invite_ring)
    )
    |> assign(:invite_search_form, to_form(%{"query" => ""}, as: :invite_search))
  end

  def refresh_invitation_requests(socket) do
    assign(
      socket,
      :invitation_requests,
      Rings.list_invitation_requests(socket.assigns.current_user)
    )
  end

  def refresh_user_ring_data(socket) do
    owned_rings = Rings.list_owned_rings(socket.assigns.current_user)

    selected_invite_ring_id =
      ensure_selected_invite_ring_id(socket.assigns.selected_invite_ring_id, owned_rings)

    socket
    |> RingManagement.refresh_user_rings_and_video_state()
    |> assign(:owned_rings, owned_rings)
    |> assign(:selected_invite_ring_id, selected_invite_ring_id)
    |> assign(
      :invite_ring_form,
      to_form(%{"ring_id" => selected_invite_ring_id || ""}, as: :invite_ring)
    )
    |> rerun_user_search()
  end

  def select_invite_ring(socket, ring_id) do
    normalized_ring_id = if ring_id == "", do: nil, else: ring_id

    socket
    |> assign(:selected_invite_ring_id, normalized_ring_id)
    |> assign(:invite_ring_form, to_form(%{"ring_id" => ring_id}, as: :invite_ring))
    |> rerun_user_search()
  end

  def search_invitees(socket, query) do
    trimmed_query = String.trim(query)

    socket
    |> assign(:invite_search_form, to_form(%{"query" => trimmed_query}, as: :invite_search))
    |> assign(:invite_search_results, search_invite_candidates(socket, trimmed_query))
  end

  def send_invite(socket, user_id) do
    ring_id = socket.assigns.selected_invite_ring_id

    with true <- is_binary(ring_id),
         {parsed_user_id, ""} <- Integer.parse(user_id),
         {:ok, _invitation} <-
           Rings.send_ring_invitation(socket.assigns.current_user, ring_id, parsed_user_id) do
      {:ok, rerun_user_search(socket), "Invitation sent."}
    else
      false ->
        {:error, socket, "Select a ring before inviting users."}

      :error ->
        {:error, socket, "Invalid user selection."}

      {:error, :already_member} ->
        {:error, socket, "That user is already a member."}

      {:error, :already_invited} ->
        {:error, socket, "That user already has a pending invite."}

      {:error, :cannot_invite_self} ->
        {:error, socket, "You cannot invite yourself."}

      {:error, :not_allowed} ->
        {:error, socket, "Only ring owners can invite users."}

      {:error, _reason} ->
        {:error, socket, "Could not send invitation."}
    end
  end

  def respond_invitation(socket, invitation_id, action) when action in ["accept", "decline"] do
    case Rings.respond_to_ring_invitation(socket.assigns.current_user, invitation_id, action) do
      {:ok, _invitation} ->
        updated_socket =
          socket
          |> refresh_user_ring_data()
          |> refresh_invitation_requests()

        message = if action == "accept", do: "Invitation accepted.", else: "Invitation declined."
        {:ok, updated_socket, message}

      {:error, _reason} ->
        {:error, socket, "Could not update invitation."}
    end
  end

  defp rerun_user_search(socket) do
    query = socket.assigns.invite_search_form.params["query"] || ""
    assign(socket, :invite_search_results, search_invite_candidates(socket, query))
  end

  defp search_invite_candidates(socket, query) do
    trimmed_query = String.trim(query)

    if trimmed_query == "" or is_nil(socket.assigns.selected_invite_ring_id) do
      []
    else
      ring_id = socket.assigns.selected_invite_ring_id

      excluded_ids =
        [socket.assigns.current_user.id] ++
          Enum.map(Rings.list_ring_members(ring_id), & &1.id) ++
          Enum.map(Rings.list_pending_invites_for_ring(ring_id), & &1.invitee_id)

      Accounts.search_users(trimmed_query, exclude_ids: excluded_ids)
    end
  end

  defp default_invite_ring_id([%{id: id} | _]), do: id
  defp default_invite_ring_id([]), do: nil

  defp ensure_selected_invite_ring_id(nil, owned_rings), do: default_invite_ring_id(owned_rings)

  defp ensure_selected_invite_ring_id(selected_ring_id, owned_rings) do
    if Enum.any?(owned_rings, &(&1.id == selected_ring_id)) do
      selected_ring_id
    else
      default_invite_ring_id(owned_rings)
    end
  end
end
