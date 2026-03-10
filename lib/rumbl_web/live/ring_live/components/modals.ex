defmodule RumblWeb.RingLive.Components.Modals do
  use RumblWeb, :html

  alias RumblWeb.RingLive.Components.Helpers, as: H

  def ring_modals(assigns) do
    ~H"""
    <%= if @selected_annotation do %>
      <div class="rumbl-modal-layer">
        <button
          type="button"
          class="rumbl-modal-backdrop"
          phx-click="clear_selected_annotation"
          aria-label="Close annotation modal"
        >
        </button>
        <section id="annotation-preview-modal" class="rumbl-video-modal">
          <div class="rumbl-video-modal-header">
            <h2 class="rumbl-video-modal-title">Annotation</h2>
            <button
              id="annotation-preview-modal-close"
              type="button"
              phx-click="clear_selected_annotation"
              class="rumbl-video-modal-close"
              aria-label="Close"
            >
              <.icon name="hero-x-mark" class="size-5" />
            </button>
          </div>

          <div class="space-y-3">
            <p class="text-sm text-base-content/70">
              {RumblWeb.VideoLive.Watch.format_time(@selected_annotation.at)} • by {@selected_annotation.author}
            </p>
            <p class="text-base text-base-content whitespace-pre-wrap break-words">
              {@selected_annotation.body}
            </p>
            <div class="rumbl-video-modal-actions">
              <button
                type="button"
                phx-click="seek_annotation_timestamp"
                phx-value-at={@selected_annotation.at}
                class="rumbl-tab is-cta"
              >
                Jump to timestamp
              </button>
            </div>
          </div>
        </section>
      </div>
    <% end %>

    <%= if @annotation_search_modal_open do %>
      <div class="rumbl-modal-layer">
        <button
          type="button"
          class="rumbl-modal-backdrop"
          phx-click="close_annotation_search_modal"
          aria-label="Close annotation search modal"
        >
        </button>
        <section id="annotation-search-modal" class="rumbl-video-modal">
          <div class="rumbl-video-modal-header">
            <h2 class="rumbl-video-modal-title">Find an annotation</h2>
            <button
              id="annotation-search-modal-close"
              type="button"
              phx-click="close_annotation_search_modal"
              class="rumbl-video-modal-close"
              aria-label="Close"
            >
              <.icon name="hero-x-mark" class="size-5" />
            </button>
          </div>

          <.form
            for={@annotation_search_form}
            id="annotation-search-form-modal"
            phx-change="search_annotations"
          >
            <.input
              field={@annotation_search_form[:query]}
              type="text"
              placeholder="Search annotation text, author, or timestamp"
            />
          </.form>

          <div class="mt-3 space-y-2">
            <%= for annotation <- @annotation_search_results do %>
              <button
                id={"annotation-search-result-#{annotation.id}"}
                type="button"
                phx-click="select_annotation_from_search"
                phx-value-annotation_id={annotation.id}
                class="rumbl-row w-full text-left"
              >
                <div class="min-w-0 flex-1">
                  <p class="truncate font-semibold text-sm text-base-content/70">
                    {RumblWeb.VideoLive.Watch.format_time(annotation.at)} • {annotation.author}
                  </p>
                  <p class="truncate font-semibold" title={annotation.body}>
                    {H.short_annotation_preview(annotation.body, 90)}
                  </p>
                </div>
                <.icon name="hero-arrow-right" class="size-4 shrink-0 text-base-content/60" />
              </button>
            <% end %>

            <%= if @annotation_search_query != "" and @annotation_search_results == [] do %>
              <p class="text-xs text-base-content/60">No annotations found.</p>
            <% end %>
          </div>
        </section>
      </div>
    <% end %>

    <%= if @invite_modal_open do %>
      <div class="rumbl-modal-layer">
        <button
          type="button"
          class="rumbl-modal-backdrop"
          phx-click="close_invite_modal"
          aria-label="Close invite modal"
        >
        </button>
        <section id="ring-invite-modal" class="rumbl-video-modal">
          <div class="rumbl-video-modal-header">
            <h2 class="rumbl-video-modal-title">Invite to {@selected_ring.name}</h2>
            <button
              id="ring-invite-modal-close"
              type="button"
              phx-click="close_invite_modal"
              class="rumbl-video-modal-close"
              aria-label="Close"
            >
              <.icon name="hero-x-mark" class="size-5" />
            </button>
          </div>

          <div class="space-y-4">
            <p class="text-sm text-base-content/70">
              Share this code with users who want to join your ring.
            </p>
            <div class="rounded-xl border border-white/15 bg-black/25 px-4 py-3">
              <p class="text-xs uppercase tracking-wider text-base-content/60">Invite Code</p>
              <p class="mt-1 text-xl font-semibold tracking-widest text-[#f2f5ff]">
                {@invite_modal_code}
              </p>
            </div>
            <div class="rumbl-video-modal-actions">
              <button type="button" phx-click="close_invite_modal" class="rumbl-tab is-cta">
                Done
              </button>
            </div>
          </div>
        </section>
      </div>
    <% end %>

    <%= if @panel_search_modal_open do %>
      <div class="rumbl-modal-layer">
        <button
          type="button"
          class="rumbl-modal-backdrop"
          phx-click="close_panel_search_modal"
          aria-label="Close search modal"
        >
        </button>
        <section id="panel-search-modal" class="rumbl-video-modal">
          <div class="rumbl-video-modal-header">
            <h2 class="rumbl-video-modal-title">Find a ring or video</h2>
            <button
              id="panel-search-modal-close"
              type="button"
              phx-click="close_panel_search_modal"
              class="rumbl-video-modal-close"
              aria-label="Close"
            >
              <.icon name="hero-x-mark" class="size-5" />
            </button>
          </div>

          <.form
            for={@panel_search_form}
            id="panel-search-form-modal"
            phx-change="search_panel_catalog"
          >
            <.input
              field={@panel_search_form[:query]}
              type="text"
              placeholder={if(@selected_ring, do: "Search video title", else: "Search ring or video")}
            />
          </.form>

          <div class="mt-3 space-y-2">
            <%= if @selected_ring do %>
              <% filtered_videos = H.filter_ring_videos(@ring_videos, @panel_search_query) %>
              <%= for video <- filtered_videos do %>
                <button
                  id={"panel-search-video-#{video.slug}"}
                  type="button"
                  phx-click="open_video_from_search"
                  phx-value-video_slug={video.slug}
                  class="rumbl-row w-full text-left"
                >
                  <div>
                    <p class="font-semibold">{video.title}</p>
                    <p class="text-xs text-base-content/60">
                      {if(video.user, do: video.user.name, else: "Unknown")}
                    </p>
                  </div>
                  <.icon name="hero-arrow-right" class="size-4 text-base-content/60" />
                </button>
              <% end %>

              <%= if @panel_search_query != "" and filtered_videos == [] do %>
                <p class="text-xs text-base-content/60">No matches found.</p>
              <% end %>
            <% else %>
              <% filtered_rings = H.filter_rings(@rings, @panel_search_query) %>
              <%= for ring <- filtered_rings do %>
                <.link
                  id={"panel-search-ring-#{ring.id}"}
                  navigate={~p"/rings/#{ring.id}"}
                  class="rumbl-row w-full text-left"
                >
                  <div>
                    <p class="font-semibold">{ring.name}</p>
                    <p class="text-xs text-base-content/60">{ring.members} members</p>
                  </div>
                  <.icon name="hero-arrow-right" class="size-4 text-base-content/60" />
                </.link>
              <% end %>

              <%= for video <- @panel_search_global_videos do %>
                <.link
                  id={"panel-search-global-video-#{video.slug}"}
                  navigate={~p"/rings/#{video.ring_id}?#{[video: video.slug]}"}
                  class="rumbl-row w-full text-left"
                >
                  <div>
                    <p class="font-semibold">{video.title}</p>
                    <p class="text-xs text-base-content/60">
                      {if(video.user, do: video.user.name, else: "Unknown")} • {H.ring_name_by_id(
                        @rings,
                        video.ring_id
                      )}
                    </p>
                  </div>
                  <.icon name="hero-arrow-right" class="size-4 text-base-content/60" />
                </.link>
              <% end %>

              <%= if @panel_search_query != "" and filtered_rings == [] and @panel_search_global_videos == [] do %>
                <p class="text-xs text-base-content/60">No matches found.</p>
              <% end %>
            <% end %>
          </div>
        </section>
      </div>
    <% end %>

    <%= if @new_ring_modal_open do %>
      <div class="rumbl-modal-layer">
        <button
          type="button"
          class="rumbl-modal-backdrop"
          phx-click="close_new_ring_modal"
          aria-label="Close new ring modal"
        >
        </button>
        <section id="new-ring-modal" class="rumbl-video-modal">
          <div class="rumbl-video-modal-header">
            <h2 class="rumbl-video-modal-title">Create Ring</h2>
            <button
              id="new-ring-modal-close"
              type="button"
              phx-click="close_new_ring_modal"
              class="rumbl-video-modal-close"
              aria-label="Close"
            >
              <.icon name="hero-x-mark" class="size-5" />
            </button>
          </div>

          <.form
            for={@new_ring_form}
            id="new-ring-form"
            phx-change="validate_new_ring"
            phx-submit="save_new_ring"
            class="rumbl-form-stack"
          >
            <.input
              field={@new_ring_form[:name]}
              type="text"
              label="Ring Name"
              placeholder="e.g. Design Crew"
              required
            />

            <div class="rumbl-video-modal-actions">
              <button type="button" phx-click="close_new_ring_modal" class="rumbl-tab">Cancel</button>
              <button type="submit" class="rumbl-tab is-cta">Create Ring</button>
            </div>
          </.form>
        </section>
      </div>
    <% end %>

    <%= if @create_category_modal_open do %>
      <div class="rumbl-modal-layer">
        <button
          type="button"
          class="rumbl-modal-backdrop"
          phx-click="close_create_category_modal"
          aria-label="Close create category modal"
        >
        </button>
        <section id="create-category-modal" class="rumbl-video-modal">
          <div class="rumbl-video-modal-header">
            <h2 class="rumbl-video-modal-title">Create Category</h2>
            <button
              id="create-category-modal-close"
              type="button"
              phx-click="close_create_category_modal"
              class="rumbl-video-modal-close"
              aria-label="Close"
            >
              <.icon name="hero-x-mark" class="size-5" />
            </button>
          </div>

          <.form
            for={@create_category_form}
            id="create-category-form"
            phx-change="validate_create_category"
            phx-submit="save_create_category"
            class="rumbl-form-stack"
          >
            <.input
              field={@create_category_form[:name]}
              type="text"
              label="Category Name"
              placeholder="e.g. Highlights"
              required
            />

            <div class="rumbl-video-modal-actions">
              <button type="button" phx-click="close_create_category_modal" class="rumbl-tab">
                Cancel
              </button>
              <button type="submit" class="rumbl-tab is-cta">Create Category</button>
            </div>
          </.form>
        </section>
      </div>
    <% end %>

    <%= if @delete_category_modal_open do %>
      <div class="rumbl-modal-layer">
        <button
          type="button"
          class="rumbl-modal-backdrop"
          phx-click="close_delete_category_modal"
          aria-label="Close delete category modal"
        >
        </button>
        <section id="delete-category-modal" class="rumbl-video-modal">
          <div class="rumbl-video-modal-header">
            <h2 class="rumbl-video-modal-title">Delete Category</h2>
            <button
              id="delete-category-modal-close"
              type="button"
              phx-click="close_delete_category_modal"
              class="rumbl-video-modal-close"
              aria-label="Close"
            >
              <.icon name="hero-x-mark" class="size-5" />
            </button>
          </div>

          <.form
            for={@delete_category_form}
            id="delete-category-form"
            phx-change="validate_delete_category"
            phx-submit="save_delete_category"
            class="rumbl-form-stack"
          >
            <.input
              field={@delete_category_form[:category_id]}
              type="select"
              label="Category"
              options={@categories}
              prompt="Choose a category"
              required
            />

            <div class="rumbl-video-modal-actions">
              <button type="button" phx-click="close_delete_category_modal" class="rumbl-tab">
                Cancel
              </button>
              <button type="submit" class="rumbl-tab is-cta">Delete Category</button>
            </div>
          </.form>
        </section>
      </div>
    <% end %>

    <%= if @join_ring_modal_open do %>
      <div class="rumbl-modal-layer">
        <button
          type="button"
          class="rumbl-modal-backdrop"
          phx-click="close_join_ring_modal"
          aria-label="Close join ring modal"
        >
        </button>
        <section id="join-ring-modal" class="rumbl-video-modal">
          <div class="rumbl-video-modal-header">
            <h2 class="rumbl-video-modal-title">Join Ring</h2>
            <button
              id="join-ring-modal-close"
              type="button"
              phx-click="close_join_ring_modal"
              class="rumbl-video-modal-close"
              aria-label="Close"
            >
              <.icon name="hero-x-mark" class="size-5" />
            </button>
          </div>

          <.form
            for={@join_ring_form}
            id="join-ring-form"
            phx-change="validate_join_ring"
            phx-submit="save_join_ring"
            class="rumbl-form-stack"
          >
            <.input
              field={@join_ring_form[:invite_code]}
              type="text"
              label="Invite Code"
              placeholder="Enter code (e.g. A1B2C3D4)"
              required
            />

            <div class="rumbl-video-modal-actions">
              <button type="button" phx-click="close_join_ring_modal" class="rumbl-tab">
                Cancel
              </button>
              <button type="submit" class="rumbl-tab is-cta">Join Ring</button>
            </div>
          </.form>
        </section>
      </div>
    <% end %>

    <%= if @video_modal_open do %>
      <div class="rumbl-modal-layer">
        <button
          type="button"
          class="rumbl-modal-backdrop"
          phx-click="close_video_modal"
          aria-label="Close add video modal"
        >
        </button>
        <section id="video-modal" class="rumbl-video-modal">
          <div class="rumbl-video-modal-header">
            <h2 class="rumbl-video-modal-title">{@video_modal_title}</h2>
            <button
              id="video-modal-close"
              type="button"
              phx-click="close_video_modal"
              class="rumbl-video-modal-close"
              aria-label="Close"
            >
              <.icon name="hero-x-mark" class="size-5" />
            </button>
          </div>

          <.form
            for={@video_modal_form}
            id="video-modal-form"
            phx-change="validate_video_modal"
            phx-submit="save_video_modal"
            class="rumbl-form-stack"
          >
            <.input field={@video_modal_form[:title]} type="text" label="Title" required />
            <.input
              field={@video_modal_form[:url]}
              type="text"
              label="YouTube URL"
              placeholder="https://www.youtube.com/watch?v=..."
              required
            />
            <.input
              field={@video_modal_form[:ring_id]}
              type="select"
              label="Workspace Ring"
              options={@ring_options}
              prompt="Choose a workspace"
              required
            />
            <.input field={@video_modal_form[:description]} type="textarea" label="Description" />
            <.input
              field={@video_modal_form[:category_id]}
              type="select"
              label="Category"
              options={@categories}
              prompt="Choose a category"
            />

            <div class="rumbl-video-modal-actions">
              <button type="button" phx-click="close_video_modal" class="rumbl-tab">Cancel</button>
              <button type="submit" class="rumbl-tab is-cta">
                {if(@video_modal_mode == :new, do: "Create Video", else: "Save Changes")}
              </button>
            </div>
          </.form>
        </section>
      </div>
    <% end %>
    """
  end
end
