defmodule RumblWeb.RingLive.Components.MainContent do
  use RumblWeb, :html

  alias RumblWeb.RingLive.Components.Helpers, as: H

  def ring_main_content(assigns) do
    ~H"""
    <main class="rumbl-content rumbl-home-content">
      <%= if @active_panel == :rings do %>
        <%= if @selected_ring do %>
          <section id="ring-workspace-section" class="rumbl-workspace">
            <div class="rumbl-content-header rumbl-channel-header">
              <div class="rumbl-channel-title-wrap">
                <.icon name="hero-hashtag" class="size-5 text-[#8ea1cf]" />
                <h1 class="rumbl-channel-title">
                  {if(@selected_video, do: @selected_video.title, else: "Select a video")}
                </h1>
              </div>

              <div class="rumbl-channel-actions">
                <button
                  id="ring-workspace-add-video"
                  type="button"
                  phx-click="open_video_modal_new"
                  phx-value-ring_id={@selected_ring.id}
                  class="rumbl-toolbar-icon-action"
                  aria-label="Add video"
                  title="Add video"
                >
                  <.icon name="hero-plus" class="size-5" />
                </button>
                <button
                  :if={
                    @selected_video && @current_user && @selected_video.user_id == @current_user.id
                  }
                  id="ring-workspace-edit-video"
                  type="button"
                  phx-click="open_video_modal_edit"
                  phx-value-video_slug={@selected_video.slug}
                  class="rumbl-toolbar-icon-action"
                  aria-label="Edit video"
                  title="Edit video"
                >
                  <.icon name="hero-pencil-square" class="size-5" />
                </button>
                <button
                  :if={
                    @selected_video && @current_user && @selected_video.user_id == @current_user.id
                  }
                  id="ring-workspace-delete-video"
                  type="button"
                  phx-click="delete_workspace_video"
                  phx-value-video_slug={@selected_video.slug}
                  data-confirm="Delete this video?"
                  class="rumbl-toolbar-icon-action is-danger"
                  aria-label="Delete video"
                  title="Delete video"
                >
                  <.icon name="hero-trash" class="size-5" />
                </button>
                <button
                  id="ring-workspace-toggle-active-now"
                  type="button"
                  phx-click="toggle_active_now_panel"
                  class="rumbl-tab"
                  aria-label={
                    if(@active_now_collapsed,
                      do: "Expand active panel",
                      else: "Collapse active panel"
                    )
                  }
                  title={if(@active_now_collapsed, do: "Show Active Now", else: "Hide Active Now")}
                >
                  <.icon
                    name={
                      if(@active_now_collapsed,
                        do: "hero-chevron-double-left",
                        else: "hero-chevron-double-right"
                      )
                    }
                    class="size-4"
                  />
                </button>
              </div>
            </div>

            <%= if @selected_video do %>
              <div class="rumbl-workspace-main grid items-stretch gap-4 lg:grid-cols-[minmax(0,1.7fr)_minmax(0,1fr)]">
                <div class="rumbl-video-column">
                  <article id="ring-selected-video" class="rumbl-video-stage">
                    <div class="rumbl-video-stage-top">
                      <h3 class="text-lg font-semibold">{@selected_video.title}</h3>
                      <span class="text-xs text-base-content/60">
                        by {if(@selected_video.user, do: @selected_video.user.name, else: "Unknown")} • {Calendar.strftime(
                          @selected_video.inserted_at,
                          "%b %d, %Y"
                        )}
                      </span>
                    </div>
                    <%= if Rumbl.Multimedia.Video.youtube_id(@selected_video) do %>
                      <div class="rumbl-video-embed-wrap">
                        <iframe
                          id="ring-video-embed"
                          phx-hook="YouTubeSeek"
                          class="rumbl-video-embed"
                          src={video_embed_src(@selected_video)}
                          title={@selected_video.title}
                          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                          referrerpolicy="strict-origin-when-cross-origin"
                          allowfullscreen
                        >
                        </iframe>
                      </div>
                    <% else %>
                      <div class="rumbl-video-placeholder">
                        <.icon name="hero-play-circle" class="size-10" />
                        <p class="mt-2 text-sm text-base-content/70">
                          Preview unavailable. This URL is not a supported YouTube link.
                        </p>
                      </div>
                    <% end %>
                  </article>

                  <section id="annotation-preview" class="rumbl-annotation-preview">
                    <p class="text-xs font-semibold uppercase tracking-wide text-base-content/60">
                      Selected Annotation
                    </p>
                    <%= if @selected_annotation do %>
                      <p class="mt-2 text-xs font-mono text-[#94b7ff]">
                        {RumblWeb.VideoLive.Watch.format_time(@selected_annotation.at)}
                      </p>
                      <p class="rumbl-annotation-preview-body">
                        {@selected_annotation.body}
                      </p>
                    <% else %>
                      <p class="mt-2 text-sm text-base-content/65">
                        Click an annotation message on the right to preview the full content here.
                      </p>
                    <% end %>
                  </section>
                </div>

                <section id="video-annotations" class="rumbl-annotations">
                  <h3 class="text-sm font-semibold uppercase tracking-wide text-base-content/70">
                    Annotations
                  </h3>
                  <div class="mt-2 space-y-2 rumbl-annotation-list">
                    <%= for annotation <- @annotations do %>
                      <article
                        id={"annotation-#{annotation.id}"}
                        phx-click="preview_annotation"
                        phx-value-annotation_id={annotation.id}
                        class={[
                          "rumbl-annotation-row",
                          @selected_annotation && @selected_annotation.id == annotation.id &&
                            "is-active"
                        ]}
                      >
                        <button
                          type="button"
                          phx-click="seek_annotation_timestamp"
                          phx-value-at={annotation.at}
                          phx-stop-propagation
                          class="rumbl-annotation-time"
                        >
                          {RumblWeb.VideoLive.Watch.format_time(annotation.at)}
                        </button>
                        <p class="rumbl-annotation-message">
                          {annotation.body}
                        </p>
                      </article>
                    <% end %>
                  </div>
                </section>
              </div>

              <section id="video-annotation-composer" class="rumbl-annotation-composer">
                <.form
                  for={@annotation_form}
                  id="annotation-form"
                  phx-submit="add_annotation"
                  class="rumbl-annotation-form"
                >
                  <div class="rumbl-composer-row">
                    <.input
                      field={@annotation_form[:at]}
                      type="text"
                      aria-label="Timestamp"
                      placeholder="0:30"
                      class="rumbl-composer-input"
                      required
                    />
                    <div class="rumbl-composer-divider" aria-hidden="true"></div>
                    <.input
                      field={@annotation_form[:body]}
                      type="textarea"
                      rows="1"
                      aria-label="Message"
                      class="rumbl-composer-input rumbl-composer-textarea"
                      phx-hook="AutoGrowTextarea"
                      placeholder="Write a note about this timestamp..."
                      required
                    />
                    <button
                      type="submit"
                      class="rumbl-tab is-cta"
                      aria-label="Post annotation"
                      title="Post annotation"
                    >
                      <.icon name="hero-paper-airplane" class="size-5" />
                    </button>
                  </div>
                </.form>
              </section>
            <% else %>
              <div class="rumbl-empty-card">
                <%= if @ring_videos == [] do %>
                  <p class="text-sm text-base-content/70">
                    No videos in this workspace yet. Add one for {String.downcase(@selected_ring.name)}.
                  </p>
                <% else %>
                  <p class="text-sm text-base-content/70">
                    Select a video from the catalog to start annotating.
                  </p>
                <% end %>
              </div>
            <% end %>
          </section>
        <% else %>
          <section id="my-rings-section" class="space-y-5">
            <div class="rumbl-content-header">
              <h1 class="text-xl font-bold tracking-tight">My Rings</h1>
              <div class="flex items-center gap-2">
                <button
                  id="rings-filter-all"
                  type="button"
                  phx-click="set_ring_filter"
                  phx-value-filter="all"
                  class={[
                    "rumbl-tab",
                    @ring_filter == :all && "is-active"
                  ]}
                >
                  All
                </button>
                <button
                  id="rings-new-button"
                  type="button"
                  phx-click="open_new_ring_modal"
                  class="rumbl-tab is-cta"
                >
                  New Ring
                </button>
                <button
                  id="rings-join-button"
                  type="button"
                  phx-click="open_join_ring_modal"
                  class="rumbl-tab"
                >
                  Join Ring
                </button>
              </div>
            </div>

            <div class="space-y-2">
              <%= for ring <- H.filter_rings(@rings, @panel_search_query) do %>
                <.link
                  id={"ring-#{ring.id}"}
                  navigate={~p"/rings/#{ring.id}"}
                  class="rumbl-row w-full text-left"
                >
                  <div class="flex items-center gap-3">
                    <div class="rumbl-avatar">{String.first(ring.name)}</div>
                    <div>
                      <p class="font-semibold">{ring.name}</p>
                      <p class="text-xs text-base-content/60">{ring.status}</p>
                    </div>
                  </div>
                  <div class="text-sm text-base-content/70">{ring.members} members</div>
                </.link>
              <% end %>
            </div>
          </section>
        <% end %>
      <% else %>
        <section id="invitation-requests-section" class="space-y-5">
          <div class="rumbl-content-header">
            <h1 class="text-xl font-bold tracking-tight">Invitation Requests</h1>
          </div>

          <section id="invite-user-section" class="rumbl-empty-card space-y-4">
            <h2 class="text-sm font-semibold uppercase tracking-wide text-base-content/70">
              Invite User
            </h2>
            <%= if @owned_rings == [] do %>
              <p class="text-sm text-base-content/70">
                You do not own any rings yet. Create a ring to invite users.
              </p>
            <% else %>
              <.form
                for={@invite_ring_form}
                id="invite-ring-select-form"
                phx-change="select_invite_ring"
                class="space-y-2"
              >
                <.input
                  field={@invite_ring_form[:ring_id]}
                  type="select"
                  label="Ring"
                  options={Enum.map(@owned_rings, fn ring -> {ring.name, ring.id} end)}
                />
              </.form>

              <.form
                for={@invite_search_form}
                id="invite-search-form"
                phx-change="search_invitees"
                class="space-y-2"
              >
                <.input
                  field={@invite_search_form[:query]}
                  type="text"
                  label="Find User"
                  placeholder="Search by name or username"
                />
              </.form>

              <div id="invite-search-results" class="space-y-2">
                <%= if @invite_search_results == [] do %>
                  <p class="text-xs text-base-content/60">
                    No users to invite for the current search.
                  </p>
                <% else %>
                  <%= for user <- @invite_search_results do %>
                    <article id={"invite-candidate-#{user.id}"} class="rumbl-row">
                      <div>
                        <p class="font-semibold">{user.name}</p>
                        <p class="text-xs text-base-content/60">@{user.username}</p>
                      </div>
                      <button
                        id={"invite-user-#{user.id}"}
                        type="button"
                        phx-click="send_invite"
                        phx-value-user_id={user.id}
                        class="rumbl-tab is-cta"
                      >
                        Invite
                      </button>
                    </article>
                  <% end %>
                <% end %>
              </div>
            <% end %>
          </section>

          <div id="incoming-invitations" class="space-y-2">
            <h2 class="text-sm font-semibold uppercase tracking-wide text-base-content/70">
              Incoming Requests
            </h2>
            <%= if @invitation_requests == [] do %>
              <div class="rumbl-empty-card">
                <p class="text-sm text-base-content/70">No pending invitation requests.</p>
              </div>
            <% else %>
              <%= for request <- @invitation_requests do %>
                <article id={"invitation-#{request.id}"} class="rumbl-row">
                  <div>
                    <p class="font-semibold">{request.ring.name}</p>
                    <p class="text-xs text-base-content/60">
                      Invited by {request.inviter.name} (@{request.inviter.username})
                    </p>
                  </div>
                  <div class="flex items-center gap-2">
                    <button
                      id={"invitation-accept-#{request.id}"}
                      type="button"
                      phx-click="respond_invitation"
                      phx-value-invitation_id={request.id}
                      phx-value-action="accept"
                      class="rumbl-tab is-cta"
                    >
                      Accept
                    </button>
                    <button
                      id={"invitation-decline-#{request.id}"}
                      type="button"
                      phx-click="respond_invitation"
                      phx-value-invitation_id={request.id}
                      phx-value-action="decline"
                      class="rumbl-tab"
                    >
                      Decline
                    </button>
                  </div>
                </article>
              <% end %>
            <% end %>
          </div>
        </section>
      <% end %>
    </main>
    """
  end

  defp video_embed_src(video) do
    "https://www.youtube.com/embed/#{Rumbl.Multimedia.Video.youtube_id(video)}?enablejsapi=1&playsinline=1"
  end
end
