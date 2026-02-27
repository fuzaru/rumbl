defmodule RumblWeb.PageLive.Home do
  use RumblWeb, :live_view

  alias Rumbl.Multimedia

  @ring_samples [
    %{id: "alpha", name: "Alpha Ring", members: 8, status: "Active"},
    %{id: "focus", name: "Focus Ring", members: 3, status: "Planning"},
    %{id: "launch", name: "Launch Circle", members: 11, status: "Live"}
  ]

  @invitation_samples [
    %{id: "alex", requester: "Alex", ring: "Alpha Ring", note: "Wants to collaborate"},
    %{id: "jo", requester: "Jo", ring: "Launch Circle", note: "Requested access yesterday"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Home")
     |> assign(:active_panel, :rings)
     |> assign(:ring_filter, :all)
     |> assign(:rings, @ring_samples)
     |> assign(:invitation_requests, @invitation_samples)
     |> assign(:selected_ring, nil)
     |> assign(:ring_videos, [])
     |> assign(:selected_video, nil)
     |> assign(:annotations, [])
     |> assign(:annotation_form, to_form(%{"body" => ""}, as: :annotation))}
  end

  @impl true
  def handle_event("select_panel", %{"panel" => "rings"}, socket) do
    {:noreply,
     socket
     |> assign(:active_panel, :rings)
     |> clear_ring_workspace()}
  end

  def handle_event("select_panel", %{"panel" => "requests"}, socket) do
    {:noreply,
     socket
     |> assign(:active_panel, :requests)
     |> clear_ring_workspace()}
  end

  @impl true
  def handle_event("set_ring_filter", %{"filter" => "all"}, socket) do
    {:noreply, assign(socket, :ring_filter, :all)}
  end

  def handle_event("select_ring", %{"ring_id" => ring_id}, socket) do
    ring = Enum.find(@ring_samples, &(&1.id == ring_id))
    videos = catalog_videos(ring_id)
    selected_video = List.first(videos)

    {:noreply,
     socket
     |> assign(:active_panel, :rings)
     |> assign(:selected_ring, ring)
     |> assign(:ring_videos, videos)
     |> assign(:selected_video, selected_video)
     |> assign(:annotations, annotations_for_video(selected_video))
     |> assign(:annotation_form, to_form(%{"body" => ""}, as: :annotation))}
  end

  def handle_event("open_video", %{"video_slug" => video_slug}, socket) do
    selected_video = Enum.find(socket.assigns.ring_videos, &(&1.slug == video_slug))

    {:noreply,
     socket
     |> assign(:selected_video, selected_video)
     |> assign(:annotations, annotations_for_video(selected_video))}
  end

  def handle_event("back_to_rings", _params, socket) do
    {:noreply, clear_ring_workspace(socket)}
  end

  def handle_event("add_annotation", %{"annotation" => %{"body" => body}}, socket) do
    trimmed_body = String.trim(body)

    cond do
      trimmed_body == "" ->
        {:noreply, assign(socket, :annotation_form, to_form(%{"body" => ""}, as: :annotation))}

      is_nil(socket.assigns.current_user) or is_nil(socket.assigns.selected_video) ->
        {:noreply, put_flash(socket, :error, "Select a video before adding annotations.")}

      true ->
        case Multimedia.annotate_video(
               socket.assigns.current_user,
               socket.assigns.selected_video.id,
               %{
                 "body" => trimmed_body,
                 "at" => 0
               }
             ) do
          {:ok, _annotation} ->
            {:noreply,
             socket
             |> assign(:annotations, annotations_for_video(socket.assigns.selected_video))
             |> assign(:annotation_form, to_form(%{"body" => ""}, as: :annotation))}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Could not add annotation.")}
        end
    end
  end

  def handle_event("delete_workspace_video", %{"video_slug" => video_slug}, socket) do
    selected_video = Enum.find(socket.assigns.ring_videos, &(&1.slug == video_slug))
    current_user = socket.assigns.current_user

    cond do
      is_nil(selected_video) ->
        {:noreply, socket}

      is_nil(current_user) or selected_video.user_id != current_user.id ->
        {:noreply, put_flash(socket, :error, "You can only delete your own videos.")}

      true ->
        {:ok, _video} = Multimedia.delete_video(selected_video)
        ring_id = if(socket.assigns.selected_ring, do: socket.assigns.selected_ring.id, else: nil)
        videos = catalog_videos(ring_id)
        next_video = List.first(videos)

        {:noreply,
         socket
         |> assign(:ring_videos, videos)
         |> assign(:selected_video, next_video)
         |> assign(:annotations, annotations_for_video(next_video))
         |> put_flash(:info, "Video deleted successfully")}
    end
  end

  def handle_event("new_ring", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "New ring creation flow is coming soon.")
     |> assign(:ring_filter, :all)}
  end

  def handle_event("join_ring", _params, socket) do
    {:noreply, put_flash(socket, :info, "Join ring flow is coming soon.")}
  end

  defp clear_ring_workspace(socket) do
    socket
    |> assign(:selected_ring, nil)
    |> assign(:ring_videos, [])
    |> assign(:selected_video, nil)
    |> assign(:annotations, [])
    |> assign(:annotation_form, to_form(%{"body" => ""}, as: :annotation))
  end

  defp annotations_for_video(nil), do: []

  defp annotations_for_video(video) do
    Multimedia.list_annotations(video)
    |> Enum.map(fn annotation ->
      %{
        id: annotation.id,
        author: annotation.user.name,
        body: annotation.body
      }
    end)
  end

  defp catalog_videos(ring_id) when is_binary(ring_id) do
    Multimedia.list_videos_for_ring(ring_id)
  end

  defp catalog_videos(_), do: []
end
