defmodule RumblWeb.RingLive.Components.Presence do
  use RumblWeb, :html

  def ring_active_now(assigns) do
    ~H"""
    <aside class={["rumbl-active-now", @selected_ring && @active_now_collapsed && "is-collapsed"]}>
      <%= if @selected_ring do %>
        <button
          id="ring-active-now-search-toggle"
          type="button"
          phx-click="open_annotation_search_modal"
          class="rumbl-panel-search mb-2 flex w-full items-center gap-2 text-left"
        >
          <.icon name="hero-magnifying-glass" class="size-4" /> Find an annotation
        </button>
      <% end %>

      <h2 class="rumbl-active-now-title">Active Now</h2>

      <%= if @selected_ring do %>
        <% online_members =
          Enum.filter(@ring_members, fn member ->
            MapSet.member?(@online_member_ids, member.id)
          end) %>
        <% offline_members =
          Enum.reject(@ring_members, fn member ->
            MapSet.member?(@online_member_ids, member.id)
          end) %>

        <section id="presence-online-ring" class="rumbl-presence-section">
          <h3 class="rumbl-presence-heading">Online — {length(online_members)}</h3>
          <div class="space-y-1">
            <%= for member <- online_members do %>
              <div id={"presence-online-#{member.id}"} class="rumbl-presence-row">
                <div class="rumbl-presence-avatar-wrap">
                  <div class="rumbl-presence-avatar">
                    {String.first(member.name || member.username || "U")}
                  </div>
                  <span class="rumbl-presence-dot is-online"></span>
                </div>
                <div class="min-w-0">
                  <p class="truncate text-sm font-semibold text-[#e8eeff]">{member.name}</p>
                  <p class="truncate text-xs text-[#8e9ab7]">@{member.username}</p>
                </div>
                <span class="rumbl-presence-badge">APP</span>
              </div>
            <% end %>
          </div>
        </section>

        <section id="presence-offline-ring" class="rumbl-presence-section">
          <h3 class="rumbl-presence-heading">Offline — {length(offline_members)}</h3>
          <div class="space-y-1">
            <%= for member <- offline_members do %>
              <div id={"presence-offline-#{member.id}"} class="rumbl-presence-row is-offline">
                <div class="rumbl-presence-avatar-wrap">
                  <div class="rumbl-presence-avatar">
                    {String.first(member.name || member.username || "U")}
                  </div>
                  <span class="rumbl-presence-dot"></span>
                </div>
                <div class="min-w-0">
                  <p class="truncate text-sm font-semibold">{member.name}</p>
                  <p class="truncate text-xs text-[#7d879f]">@{member.username}</p>
                </div>
              </div>
            <% end %>
          </div>
        </section>
      <% else %>
        <% active_entries =
          @active_ring_users
          |> Enum.map(fn user ->
            %{
              id: user.id,
              name: user.name,
              subtitle: Enum.join(user.rings, ", ")
            }
          end) %>

        <div class="rumbl-active-now-meta">
          <p class="text-xs font-medium uppercase tracking-wide text-[#8e9ab7]">
            Workspace Activity
          </p>
          <span class="rumbl-active-now-count">{length(active_entries)}</span>
        </div>

        <div class="rumbl-active-feed">
          <%= if active_entries == [] do %>
            <div class="rumbl-active-now-card">
              <p class="rumbl-active-now-headline">It's quiet for now...</p>
              <p class="rumbl-active-now-copy">
                When a ring member starts an activity, you'll see it here.
              </p>
            </div>
          <% else %>
            <%= for entry <- active_entries do %>
              <div
                id={"active-now-user-#{entry.id}"}
                class={["rumbl-presence-row", "rumbl-active-feed-row"]}
              >
                <div class="rumbl-presence-avatar-wrap">
                  <div class="rumbl-presence-avatar">
                    {String.first(entry.name || "U")}
                  </div>
                  <span class="rumbl-presence-dot is-online"></span>
                </div>
                <div class="min-w-0">
                  <p class="truncate text-sm font-semibold text-[#e8eeff]">{entry.name}</p>
                  <p class="truncate text-xs text-[#8e9ab7]">{entry.subtitle}</p>
                </div>
                <span class="rumbl-presence-badge">APP</span>
              </div>
            <% end %>
          <% end %>
        </div>
      <% end %>
    </aside>
    """
  end
end
