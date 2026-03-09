defmodule RumblWeb.VideoLive.Modal do
  alias Rumbl.Multimedia
  alias Rumbl.Multimedia.Video

  def init_assigns(socket, ring_options) do
    socket
    |> assign_category_options_for_ring(nil)
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
    |> assign_category_options_for_ring(ring_id)
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
      |> assign_category_options_for_ring(video.ring_id)
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
    selected_ring_id = Map.get(video_params, "ring_id", "")

    changeset =
      socket.assigns.video_modal_video
      |> Multimedia.change_video(video_params)
      |> Map.put(:action, :validate)

    socket
    |> assign_category_options_for_ring(selected_ring_id)
    |> Phoenix.Component.assign(:video_modal_form, Phoenix.Component.to_form(changeset))
  end

  def save_modal(socket, video_params) do
    result =
      case socket.assigns.video_modal_mode do
        :new -> Multimedia.create_video(socket.assigns.current_user, video_params)
        :edit -> Multimedia.update_video(socket.assigns.video_modal_video, video_params)
      end

    case result do
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

  defp assign_category_options_for_ring(socket, ring_id) when is_binary(ring_id) do
    categories = Multimedia.list_categories_for_ring(ring_id)

    socket
    |> Phoenix.Component.assign(:all_categories, categories)
    |> Phoenix.Component.assign(:categories, Enum.map(categories, &{&1.name, &1.id}))
  end

  defp assign_category_options_for_ring(socket, _ring_id) do
    socket
    |> Phoenix.Component.assign(:all_categories, [])
    |> Phoenix.Component.assign(:categories, [])
  end
end
