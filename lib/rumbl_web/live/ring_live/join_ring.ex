defmodule RumblWeb.RingLive.JoinRing do
  use RumblWeb, :live_view

  alias Rumbl.Rings

  @impl true
  def mount(_params, _session, socket) do
    rings = Rings.list_user_rings(socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:page_title, "Join Ring")
     |> assign(:rings, rings)
     |> assign(:form, to_form(join_changeset(%{}), as: :join_ring))}
  end

  @impl true
  def handle_event("validate", %{"join_ring" => params}, socket) do
    changeset =
      params
      |> join_changeset()
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: :join_ring))}
  end

  def handle_event("save", %{"join_ring" => %{"invite_code" => invite_code} = params}, socket) do
    case Rings.join_ring_by_invite(socket.assigns.current_user, invite_code) do
      {:ok, ring} ->
        {:noreply,
         socket
         |> put_flash(:info, "Joined #{ring.name}.")
         |> push_navigate(to: ~p"/rings/#{ring.id}")}

      {:error, :invalid_code} ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid invite code.")
         |> assign(
           :form,
           to_form(add_code_error(params, "Invite code is invalid"), as: :join_ring)
         )}

      {:error, :already_member} ->
        {:noreply,
         socket
         |> assign(
           :form,
           to_form(add_code_error(params, "You are already a member of that ring."),
             as: :join_ring
           )
         )}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not join ring. Please try again.")}
    end
  end

  defp join_changeset(params) do
    types = %{invite_code: :string}

    {%{}, types}
    |> Ecto.Changeset.cast(params, [:invite_code])
    |> Ecto.Changeset.update_change(:invite_code, &String.trim/1)
    |> Ecto.Changeset.validate_required([:invite_code])
    |> Ecto.Changeset.validate_length(:invite_code, min: 6, max: 20)
  end

  defp add_code_error(params, message) do
    params
    |> join_changeset()
    |> Map.put(:action, :validate)
    |> Ecto.Changeset.add_error(:invite_code, message)
  end
end
