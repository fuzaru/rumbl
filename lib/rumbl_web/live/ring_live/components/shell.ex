defmodule RumblWeb.RingLive.Components.Shell do
  use RumblWeb, :html

  alias RumblWeb.RingLive.Components.Helpers, as: H

  def ring_side_rail(assigns) do
    ~H"""
    <aside class="rumbl-rail">
      <.link
        id="home-logo-entry"
        navigate={~p"/rings"}
        class={[
          "rumbl-rail-logo",
          is_nil(@selected_ring) && "is-active"
        ]}
      >
        <img src={~p"/images/logo.png"} alt="Rumbl logo" class="h-8 w-8 object-contain" />
      </.link>
      <div class="rumbl-rail-divider" />
      <.link
        :for={ring <- @rings}
        id={"rail-ring-#{ring.id}"}
        navigate={~p"/rings/#{ring.id}"}
        class={[
          "rumbl-rail-node",
          @selected_ring && @selected_ring.id == ring.id && "is-active"
        ]}
      >
        {String.first(ring.name)}
      </.link>
      <button
        id="home-rail-add"
        type="button"
        phx-click="open_new_ring_modal"
        class="rumbl-rail-node is-add"
      >
        <.icon name="hero-plus" class="size-6" />
      </button>
    </aside>
    """
  end

  def ring_left_panel(assigns) do
    ~H"""
    <aside class="rumbl-panel">
      <%= if @active_panel == :rings and @selected_ring do %>
        <div class="rumbl-panel-header">
          <.link id="ring-workspace-back" navigate={~p"/rings"} class="rumbl-panel-back">
            <.icon name="hero-arrow-left" class="size-4" /> Rings
          </.link>
          <h2 class="rumbl-panel-title">{@selected_ring.name}</h2>
          <p class="rumbl-panel-subtitle">Video Catalog</p>
        </div>

        <.form
          for={@panel_search_form}
          id="panel-search-form"
          phx-change="search_panel_catalog"
          class="mt-2"
        >
          <.input field={@panel_search_form[:query]} type="text" placeholder="Search video title" />
        </.form>

        <div id="ring-video-catalog" class="rumbl-panel-video-list">
          <%= for video <- H.filter_ring_videos(@ring_videos, @panel_search_query) do %>
            <button
              id={"catalog-video-#{video.slug}"}
              type="button"
              phx-click="open_video"
              phx-value-video_slug={video.slug}
              class={[
                "rumbl-panel-video-item",
                @selected_video && @selected_video.slug == video.slug && "is-active"
              ]}
            >
              <div class="rumbl-panel-video-thumb">
                <.icon name="hero-play-circle" class="size-5" />
              </div>
              <div class="min-w-0 text-left">
                <p class="truncate text-sm font-semibold">{video.title}</p>
                <p class="truncate text-xs text-base-content/60">
                  {if(video.user, do: video.user.name, else: "Unknown")} • {Calendar.strftime(
                    video.inserted_at,
                    "%b %d, %Y"
                  )}
                </p>
              </div>
            </button>
          <% end %>
        </div>
      <% else %>
        <button
          id="panel-search-toggle"
          type="button"
          phx-click="open_panel_search_modal"
          class="rumbl-panel-search w-full text-left"
        >
          Find a ring
        </button>

        <div class="rumbl-panel-nav">
          <.link
            id="panel-my-rings"
            navigate={~p"/rings"}
            class={[
              "rumbl-panel-item",
              @active_panel == :rings && "is-active"
            ]}
          >
            <.icon name="hero-user-group" class="size-4" /> My Rings
          </.link>

          <.link id="panel-my-videos" navigate={~p"/videos"} class="rumbl-panel-item">
            <.icon name="hero-play-circle" class="size-4" /> My Videos
          </.link>

          <.link
            id="panel-invitation-requests"
            navigate={~p"/invitations"}
            class={[
              "rumbl-panel-item",
              @active_panel == :requests && "is-active"
            ]}
          >
            <.icon name="hero-envelope" class="size-4" /> Invitation Requests
          </.link>
        </div>
      <% end %>
    </aside>
    """
  end

  def ring_bottom_profile(assigns) do
    ~H"""
    <%= if @current_user do %>
      <div class="rumbl-bottom-profile-wrap">
        <div class="rumbl-bottom-profile">
          <.link
            id="home-bottom-profile"
            navigate={~p"/users/#{@current_user.id}"}
            class="rumbl-bottom-profile-main"
          >
            <div class="rumbl-profile-avatar">
              {String.first(@current_user.username || @current_user.name || "R")}
            </div>
            <div class="min-w-0">
              <p class="truncate text-sm font-semibold text-[#f2f5ff]">{@current_user.name}</p>
              <p class="truncate text-xs text-[#9ea9c5]">@{@current_user.username}</p>
            </div>
          </.link>
          <.link
            id="home-bottom-logout"
            href={~p"/sessions"}
            method="delete"
            class="rumbl-bottom-profile-logout"
          >
            <.icon name="hero-arrow-left-on-rectangle" class="size-4" />
          </.link>
        </div>
      </div>
    <% end %>
    """
  end
end
