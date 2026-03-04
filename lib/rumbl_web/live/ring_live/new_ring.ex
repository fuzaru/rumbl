defmodule RumblWeb.RingLive.NewRing do
  use RumblWeb, :live_view

  alias Rumbl.Rings

  @impl true
  def mount(_params, _session, socket) do
    rings = Rings.list_user_rings(socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:page_title, "New Ring")
     |> assign(:rings, rings)
     |> assign(:form, to_form(ring_changeset(%{}), as: :ring))}
  end

  @impl true
  def handle_event("validate", %{"ring" => ring_params}, socket) do
    changeset =
      ring_params
      |> ring_changeset()
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: :ring))}
  end

  def handle_event("save", %{"ring" => ring_params}, socket) do
    changeset = ring_changeset(ring_params)

    if changeset.valid? do
      case Rings.create_ring(socket.assigns.current_user, ring_params) do
        {:ok, ring} ->
          {:noreply,
           socket
           |> put_flash(:info, "Ring created. Invite code: #{ring.invite_code}")
           |> push_navigate(to: ~p"/rings/#{ring.id}")}

        {:error, _changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, "Could not create ring. Please try again.")
           |> assign(:form, to_form(changeset, as: :ring))}
      end
    else
      {:noreply,
       assign(socket, :form, to_form(Map.put(changeset, :action, :validate), as: :ring))}
    end
  end

  defp ring_changeset(params) do
    types = %{name: :string}

    {%{}, types}
    |> Ecto.Changeset.cast(params, [:name])
    |> Ecto.Changeset.validate_required([:name])
    |> Ecto.Changeset.validate_length(:name, min: 2, max: 60)
  end
end
