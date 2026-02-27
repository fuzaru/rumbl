defmodule RumblWeb.VideoLive.Form do
  use RumblWeb, :live_view

  alias Rumbl.Multimedia
  alias Rumbl.Multimedia.Video

  @ring_options [
    {"Alpha Ring", "alpha"},
    {"Focus Ring", "focus"},
    {"Launch Circle", "launch"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:categories, Multimedia.category_options())
     |> assign(:ring_options, @ring_options)
     |> assign(:return_ring_id, nil)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_live_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("validate", %{"video" => video_params}, socket) do
    changeset =
      socket.assigns.video
      |> Multimedia.change_video(video_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"video" => video_params}, socket) do
    case socket.assigns.live_action do
      :new ->
        case Multimedia.create_video(socket.assigns.current_user, video_params) do
          {:ok, video} ->
            {:noreply,
             socket
             |> put_flash(:info, "Video created successfully.")
             |> push_navigate(to: return_to_path(socket, video.slug))}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset))}
        end

      :edit ->
        case Multimedia.update_video(socket.assigns.video, video_params) do
          {:ok, video} ->
            {:noreply,
             socket
             |> put_flash(:info, "Video updated successfully.")
             |> push_navigate(to: return_to_path(socket, video.slug))}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset))}
        end
    end
  end

  def handle_event("delete", _params, socket) do
    {:ok, _video} = Multimedia.delete_video(socket.assigns.video)

    {:noreply,
     socket
     |> put_flash(:info, "Video deleted successfully.")
     |> push_navigate(to: return_to_path(socket))}
  end

  def init_assigns(socket, ring_options) do
    socket
    |> Phoenix.Component.assign(:categories, Multimedia.category_options())
    |> Phoenix.Component.assign(:ring_options, ring_options)
    |> Phoenix.Component.assign(:video_modal_open, false)
    |> Phoenix.Component.assign(:video_modal_mode, :new)
    |> Phoenix.Component.assign(:video_modal_title, "Add Video")
    |> Phoenix.Component.assign(:video_modal_video, %Video{})
    |> Phoenix.Component.assign(
      :video_modal_form,
      Phoenix.Component.to_form(Multimedia.change_video(%Video{}))
    )
  end

  def open_new_modal(socket, ring_id) do
    changeset = Multimedia.change_video(%Video{}, %{"ring_id" => ring_id || ""})

    socket
    |> Phoenix.Component.assign(:video_modal_open, true)
    |> Phoenix.Component.assign(:video_modal_mode, :new)
    |> Phoenix.Component.assign(:video_modal_title, "Add Video")
    |> Phoenix.Component.assign(:video_modal_video, %Video{})
    |> Phoenix.Component.assign(:video_modal_form, Phoenix.Component.to_form(changeset))
  end

  def open_edit_modal(socket, slug) do
    try do
      video = Multimedia.get_user_video!(socket.assigns.current_user, slug)
      changeset = Multimedia.change_video(video)

      socket
      |> Phoenix.Component.assign(:video_modal_open, true)
      |> Phoenix.Component.assign(:video_modal_mode, :edit)
      |> Phoenix.Component.assign(:video_modal_title, "Edit Video")
      |> Phoenix.Component.assign(:video_modal_video, video)
      |> Phoenix.Component.assign(:video_modal_form, Phoenix.Component.to_form(changeset))
    rescue
      Ecto.NoResultsError ->
        socket
        |> Phoenix.LiveView.put_flash(:error, "Video not found.")
        |> Phoenix.Component.assign(:video_modal_open, false)
    end
  end

  def close_modal(socket), do: Phoenix.Component.assign(socket, :video_modal_open, false)

  def validate_modal(socket, video_params) do
    changeset =
      socket.assigns.video_modal_video
      |> Multimedia.change_video(video_params)
      |> Map.put(:action, :validate)

    Phoenix.Component.assign(socket, :video_modal_form, Phoenix.Component.to_form(changeset))
  end

  def save_modal(socket, video_params) do
    case socket.assigns.video_modal_mode do
      :new ->
        case Multimedia.create_video(socket.assigns.current_user, video_params) do
          {:ok, video} ->
            {:ok, video.slug}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:error,
             Phoenix.Component.assign(
               socket,
               :video_modal_form,
               Phoenix.Component.to_form(changeset)
             )}
        end

      :edit ->
        case Multimedia.update_video(socket.assigns.video_modal_video, video_params) do
          {:ok, video} ->
            {:ok, video.slug}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:error,
             Phoenix.Component.assign(
               socket,
               :video_modal_form,
               Phoenix.Component.to_form(changeset)
             )}
        end
    end
  end

  defp apply_live_action(socket, :new, params) do
    video = %Video{}
    ring_id = params["ring"] || ""

    socket
    |> assign(:page_title, "Add Video")
    |> assign(:video, video)
    |> assign(:return_ring_id, ring_id)
    |> assign(:form, to_form(Multimedia.change_video(video, %{"ring_id" => ring_id})))
  end

  defp apply_live_action(socket, :edit, %{"id" => id} = params) do
    video = Multimedia.get_user_video!(socket.assigns.current_user, id)

    socket
    |> assign(:page_title, "Edit Video")
    |> assign(:video, video)
    |> assign(:return_ring_id, params["ring"])
    |> assign(:form, to_form(Multimedia.change_video(video)))
  end

  defp return_to_path(socket, preferred_slug \\ nil) do
    case socket.assigns.return_ring_id do
      ring_id when is_binary(ring_id) and ring_id != "" and is_binary(preferred_slug) ->
        ~p"/rings/#{ring_id}?#{[video: preferred_slug]}"

      ring_id when is_binary(ring_id) and ring_id != "" ->
        ~p"/rings/#{ring_id}"

      _ ->
        ~p"/videos"
    end
  end
end
