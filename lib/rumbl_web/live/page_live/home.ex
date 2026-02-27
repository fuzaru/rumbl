defmodule RumblWeb.PageLive.Home do
  use RumblWeb, :live_view

  @ring_samples [
    %{id: "alpha", name: "Alpha Ring", members: 8, status: "Active"},
    %{id: "focus", name: "Focus Ring", members: 3, status: "Planning"},
    %{id: "launch", name: "Launch Circle", members: 11, status: "Live"}
  ]

  @invitation_samples [
    %{id: "alex", requester: "Alex", ring: "Alpha Ring", note: "Wants to collaborate"},
    %{id: "jo", requester: "Jo", ring: "Launch Circle", note: "Requested access yesterday"}
  ]

  @ring_videos %{
    "alpha" => [
      %{id: "alpha_intro", title: "Alpha Kickoff", owner: "Ram", duration: "08:12"},
      %{id: "alpha_review", title: "Design Review", owner: "Maya", duration: "14:35"},
      %{id: "alpha_sync", title: "Weekly Sync", owner: "Noah", duration: "06:42"}
    ],
    "focus" => [
      %{id: "focus_deep", title: "Deep Work Session", owner: "Ari", duration: "21:04"},
      %{id: "focus_notes", title: "Research Notes", owner: "Ram", duration: "10:11"}
    ],
    "launch" => [
      %{id: "launch_demo", title: "Launch Demo", owner: "Kai", duration: "09:18"},
      %{id: "launch_feedback", title: "Feedback Roundup", owner: "Lena", duration: "07:56"}
    ]
  }

  @video_annotations %{
    "alpha_intro" => [
      %{id: "a1", author: "Maya", body: "Great pacing in the first segment."},
      %{id: "a2", author: "Ram", body: "Let's tighten the ending transition."}
    ],
    "alpha_review" => [
      %{id: "a3", author: "Noah", body: "Timestamp 03:12 needs clearer narration."}
    ],
    "focus_deep" => [
      %{id: "a4", author: "Ari", body: "Add a marker where the task list changes."}
    ]
  }

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
    videos = Map.get(@ring_videos, ring_id, [])
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

  def handle_event("open_video", %{"video_id" => video_id}, socket) do
    selected_video = Enum.find(socket.assigns.ring_videos, &(&1.id == video_id))

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

    if trimmed_body == "" do
      {:noreply, assign(socket, :annotation_form, to_form(%{"body" => ""}, as: :annotation))}
    else
      author =
        if socket.assigns.current_user do
          socket.assigns.current_user.name
        else
          "You"
        end

      new_annotation = %{
        id: "tmp-#{System.unique_integer([:positive])}",
        author: author,
        body: trimmed_body
      }

      {:noreply,
       socket
       |> assign(:annotations, socket.assigns.annotations ++ [new_annotation])
       |> assign(:annotation_form, to_form(%{"body" => ""}, as: :annotation))}
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
    Map.get(@video_annotations, video.id, [])
  end
end
