defmodule RumblWeb.RingLive.Index.RingManagement do
  import Phoenix.Component, only: [assign: 3, to_form: 2]

  alias Rumbl.Rings
  alias RumblWeb.VideoLive.Index, as: VideoState

  def init_assigns(socket) do
    socket
    |> assign(:new_ring_modal_open, false)
    |> assign(:join_ring_modal_open, false)
    |> assign(:new_ring_form, to_form(ring_changeset(%{}), as: :ring))
    |> assign(:join_ring_form, to_form(join_ring_changeset(%{}), as: :join_ring))
  end

  def refresh_user_rings_and_video_state(socket) do
    rings = Rings.list_user_rings(socket.assigns.current_user)
    ring_options = Rings.ring_options(rings)

    socket
    |> assign(:rings, rings)
    |> VideoState.init(ring_options)
  end

  def open_new_modal(socket) do
    socket
    |> assign(:new_ring_modal_open, true)
    |> assign(:new_ring_form, to_form(ring_changeset(%{}), as: :ring))
  end

  def close_new_modal(socket), do: assign(socket, :new_ring_modal_open, false)

  def validate_new_modal(socket, ring_params) do
    changeset = ring_params |> ring_changeset() |> Map.put(:action, :validate)
    assign(socket, :new_ring_form, to_form(changeset, as: :ring))
  end

  def save_new_ring(socket, ring_params) do
    changeset = ring_changeset(ring_params)

    if changeset.valid? do
      case Rings.create_ring(socket.assigns.current_user, ring_params) do
        {:ok, ring} ->
          {:noreply,
           socket
           |> refresh_user_rings_and_video_state()
           |> assign(:new_ring_modal_open, false)
           |> Phoenix.LiveView.put_flash(:info, "Ring created. Invite code: #{ring.invite_code}")
           |> Phoenix.LiveView.push_navigate(to: "/rings/#{ring.id}")}

        {:error, _} ->
          {:noreply,
           socket
           |> Phoenix.LiveView.put_flash(:error, "Could not create ring. Please try again.")
           |> assign(:new_ring_form, to_form(changeset, as: :ring))}
      end
    else
      {:noreply,
       assign(socket, :new_ring_form, to_form(%{changeset | action: :validate}, as: :ring))}
    end
  end

  def open_join_modal(socket) do
    socket
    |> assign(:join_ring_modal_open, true)
    |> assign(:join_ring_form, to_form(join_ring_changeset(%{}), as: :join_ring))
  end

  def close_join_modal(socket), do: assign(socket, :join_ring_modal_open, false)

  def validate_join_modal(socket, join_params) do
    changeset = join_params |> join_ring_changeset() |> Map.put(:action, :validate)
    assign(socket, :join_ring_form, to_form(changeset, as: :join_ring))
  end

  def save_join_ring(socket, %{"invite_code" => invite_code} = params) do
    case Rings.join_ring_by_invite(socket.assigns.current_user, invite_code) do
      {:ok, ring} ->
        {:noreply,
         socket
         |> refresh_user_rings_and_video_state()
         |> assign(:join_ring_modal_open, false)
         |> Phoenix.LiveView.put_flash(:info, "Joined #{ring.name}.")
         |> Phoenix.LiveView.push_navigate(to: "/rings/#{ring.id}")}

      {:error, :invalid_code} ->
        {:noreply,
         socket
         |> Phoenix.LiveView.put_flash(:error, "Invalid invite code.")
         |> assign(
           :join_ring_form,
           to_form(add_join_code_error(params, "Invite code is invalid"), as: :join_ring)
         )}

      {:error, :already_member} ->
        {:noreply,
         socket
         |> assign(
           :join_ring_form,
           to_form(add_join_code_error(params, "You are already a member of that ring."),
             as: :join_ring
           )
         )}

      {:error, _changeset} ->
        {:noreply,
         Phoenix.LiveView.put_flash(socket, :error, "Could not join ring. Please try again.")}
    end
  end

  def delete_selected_ring(socket) do
    ring = socket.assigns.selected_ring
    current_user = socket.assigns.current_user

    cond do
      is_nil(ring) ->
        {:noreply, Phoenix.LiveView.put_flash(socket, :error, "No ring is selected.")}

      is_nil(current_user) or ring.owner_id != current_user.id ->
        {:noreply,
         Phoenix.LiveView.put_flash(socket, :error, "Only the ring owner can delete this ring.")}

      true ->
        case Rings.delete_owned_ring(current_user, ring.id) do
          {:ok, _deleted_ring} ->
            {:noreply,
             socket
             |> refresh_user_rings_and_video_state()
             |> Phoenix.LiveView.put_flash(:info, "Ring deleted.")
             |> Phoenix.LiveView.push_navigate(to: "/rings")}

          {:error, :not_found} ->
            {:noreply, Phoenix.LiveView.put_flash(socket, :error, "That ring no longer exists.")}

          {:error, :forbidden} ->
            {:noreply,
             Phoenix.LiveView.put_flash(
               socket,
               :error,
               "Only the ring owner can delete this ring."
             )}

          {:error, _reason} ->
            {:noreply,
             Phoenix.LiveView.put_flash(
               socket,
               :error,
               "Could not delete ring. Please try again."
             )}
        end
    end
  end

  defp ring_changeset(params) do
    types = %{name: :string}

    {%{}, types}
    |> Ecto.Changeset.cast(params, [:name])
    |> Ecto.Changeset.validate_required([:name])
    |> Ecto.Changeset.validate_length(:name, min: 2, max: 60)
  end

  defp join_ring_changeset(params) do
    types = %{invite_code: :string}

    {%{}, types}
    |> Ecto.Changeset.cast(params, [:invite_code])
    |> Ecto.Changeset.update_change(:invite_code, &String.trim/1)
    |> Ecto.Changeset.validate_required([:invite_code])
    |> Ecto.Changeset.validate_length(:invite_code, min: 6, max: 20)
  end

  defp add_join_code_error(params, message) do
    params
    |> join_ring_changeset()
    |> Map.put(:action, :validate)
    |> Ecto.Changeset.add_error(:invite_code, message)
  end
end
