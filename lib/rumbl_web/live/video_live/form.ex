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
     |> assign(:ring_options, @ring_options)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("validate", %{"video" => video_params}, socket) do
    changeset =
      socket.assigns.video
      |> Multimedia.change_video(video_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"video" => video_params}, socket) do
    save_video(socket, socket.assigns.live_action, video_params)
  end

  def handle_event("delete", _params, socket) do
    {:ok, _video} = Multimedia.delete_video(socket.assigns.video)

    {:noreply,
     socket
     |> put_flash(:info, "Video deleted successfully")
     |> push_navigate(to: ~p"/videos")}
  end

  defp apply_action(socket, :new, params) do
    ring_id = normalize_ring_id(params["ring"])

    socket
    |> assign(:page_title, "Add New Video")
    |> assign(:video, %Video{})
    |> assign_form(Multimedia.change_video(%Video{}, %{"ring_id" => ring_id}))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    video = Multimedia.get_user_video!(socket.assigns.current_user, id)

    socket
    |> assign(:page_title, "Edit Video")
    |> assign(:video, video)
    |> assign_form(Multimedia.change_video(video))
  end

  defp save_video(socket, :new, video_params) do
    case Multimedia.create_video(socket.assigns.current_user, video_params) do
      {:ok, video} ->
        {:noreply,
         socket
         |> put_flash(:info, "Video created successfully")
         |> push_navigate(to: ~p"/videos/#{video}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_video(socket, :edit, video_params) do
    case Multimedia.update_video(socket.assigns.video, video_params) do
      {:ok, video} ->
        {:noreply,
         socket
         |> put_flash(:info, "Video updated successfully")
         |> push_navigate(to: ~p"/videos/#{video}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp normalize_ring_id(ring_id) when is_binary(ring_id) do
    if Enum.any?(@ring_options, fn {_name, option_id} -> option_id == ring_id end) do
      ring_id
    else
      ""
    end
  end

  defp normalize_ring_id(_), do: ""
end
