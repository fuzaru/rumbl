defmodule RumblWeb.VideoLive.Form do
  alias Rumbl.Multimedia
  alias Rumbl.Multimedia.Video

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
end
