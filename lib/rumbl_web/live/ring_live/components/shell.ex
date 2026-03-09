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
          <div class="rumbl-panel-header-top">
            <details
              id="ring-workspace-menu-details"
              class="rumbl-panel-menu"
              phx-hook="PersistDetailsOpen"
            >
              <summary id="ring-workspace-menu" class="rumbl-panel-menu-summary">
                <h2 class="rumbl-panel-title">{@selected_ring.name}</h2>
                <.icon
                  name="hero-chevron-down"
                  class="rumbl-dropdown-chevron size-4 text-[#a8b4d1]"
                />
              </summary>
              <div class="rumbl-panel-menu-items">
                <button
                  id="ring-create-category-trigger"
                  type="button"
                  phx-click="open_create_category_modal"
                  class="rumbl-panel-menu-item"
                >
                  <.icon name="hero-folder-plus" class="size-4" /> Create category
                </button>
                <button
                  id="ring-delete-category-trigger"
                  type="button"
                  phx-click="open_delete_category_modal"
                  class="rumbl-panel-menu-item"
                >
                  <.icon name="hero-trash" class="size-4" /> Delete category
                </button>
              </div>
            </details>

            <button
              id="ring-panel-invite"
              type="button"
              phx-click="show_invite_code"
              class="rumbl-toolbar-icon-action"
              aria-label="Invite"
              title="Invite"
            >
              <.icon name="hero-envelope" class="size-5" />
            </button>
          </div>
        </div>

        <div id="ring-video-catalog" class="rumbl-panel-video-list">
          <% grouped_videos =
            H.grouped_ring_videos(@ring_videos, @all_categories, @panel_search_query) %>
          <%= if grouped_videos == [] do %>
            <div class="rumbl-empty-card">
              <p class="text-sm font-bold text-base-content/70">
                It's so empty here... Create a category or add a video to get started.
              </p>
            </div>
          <% end %>
          <%= for group <- grouped_videos do %>
            <details
              id={"catalog-category-cat-#{group.id}"}
              class="rumbl-panel-category-group"
              phx-hook="PersistDetailsOpen"
            >
              <summary
                id={"catalog-category-summary-cat-#{group.id}"}
                class="rumbl-panel-category-summary"
              >
                <h3 class="rumbl-panel-category-title">{group.category}</h3>
                <.icon
                  name="hero-chevron-down"
                  class="rumbl-dropdown-chevron size-4 text-[#8ea1cf]"
                />
              </summary>

              <div class="rumbl-panel-category-videos">
                <%= if group.videos == [] do %>
                  <p class="rumbl-panel-category-empty">No videos in this category yet.</p>
                <% else %>
                  <%= for video <- group.videos do %>
                    <button
                      id={"catalog-video-#{video.slug}"}
                      type="button"
                      phx-click="open_video"
                      phx-value-video_slug={video.slug}
                      class={[
                        "rumbl-panel-channel-item",
                        @selected_video && @selected_video.slug == video.slug && "is-active"
                      ]}
                    >
                      <.icon name="hero-hashtag" class="size-4 text-[#8ea1cf]" />
                      <span class="truncate">{video.title}</span>
                    </button>
                  <% end %>
                <% end %>
              </div>
            </details>
          <% end %>
        </div>
      <% else %>
        <button
          id="panel-search-toggle"
          type="button"
          phx-click="open_panel_search_modal"
          class="rumbl-panel-search flex w-full items-center gap-2 text-left"
        >
          <.icon name="hero-magnifying-glass" class="size-4" /> Find a ring or video
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
          <details
            id="home-bottom-profile-menu"
            class="rumbl-bottom-profile-menu"
            phx-hook="PersistDetailsOpen"
          >
            <summary id="home-bottom-profile" class="rumbl-bottom-profile-main">
              <div class="rumbl-profile-avatar">
                {String.first(@current_user.username || @current_user.name || "R")}
              </div>
              <div class="min-w-0">
                <p class="truncate text-sm font-semibold text-[#f2f5ff]">{@current_user.name}</p>
                <p class="truncate text-xs text-[#9ea9c5]">@{@current_user.username}</p>
              </div>
              <.icon
                name="hero-chevron-up"
                class="rumbl-dropdown-chevron ml-auto size-4 text-[#9ea9c5]"
              />
            </summary>
            <div class="rumbl-bottom-profile-menu-items">
              <.link id="home-edit-profile" navigate={~p"/user"} class="rumbl-panel-menu-item">
                <.icon name="hero-pencil-square" class="size-4" /> Edit Profile
              </.link>
            </div>
          </details>
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
