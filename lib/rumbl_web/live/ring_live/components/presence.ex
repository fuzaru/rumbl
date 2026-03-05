defmodule RumblWeb.RingLive.Components.Presence do
  use RumblWeb, :html

  def ring_active_now(assigns) do
    ~H"""
    <aside class="rumbl-active-now">
      <h2 class="rumbl-active-now-title">Active Now</h2>

      <%= if @selected_ring do %>
        <% online_members =
          Enum.filter(@ring_members, fn member -> MapSet.member?(@online_member_ids, member.id) end) %>
        <% offline_members =
          Enum.reject(@ring_members, fn member -> MapSet.member?(@online_member_ids, member.id) end) %>

        <section id="presence-online-ring" class="rumbl-presence-section">
          <h3 class="rumbl-presence-heading">Online — {length(online_members)}</h3>
          <div class="space-y-1">
            <%= for member <- online_members do %>
              <.link
                id={"presence-online-#{member.id}"}
                navigate={~p"/users/#{member.id}"}
                class="rumbl-presence-row"
              >
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
              </.link>
            <% end %>
          </div>
        </section>

        <section id="presence-offline-ring" class="rumbl-presence-section">
          <h3 class="rumbl-presence-heading">Offline — {length(offline_members)}</h3>
          <div class="space-y-1">
            <%= for member <- offline_members do %>
              <.link
                id={"presence-offline-#{member.id}"}
                navigate={~p"/users/#{member.id}"}
                class="rumbl-presence-row is-offline"
              >
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
              </.link>
            <% end %>
          </div>
        </section>
      <% else %>
        <section id="presence-online-global" class="rumbl-presence-section">
          <h3 class="rumbl-presence-heading">Online — {length(@active_ring_users)}</h3>
          <div class="space-y-1">
            <%= for user <- @active_ring_users do %>
              <.link
                id={"presence-online-#{user.id}"}
                navigate={~p"/users/#{user.id}"}
                class="rumbl-presence-row"
              >
                <div class="rumbl-presence-avatar-wrap">
                  <div class="rumbl-presence-avatar">
                    {String.first(user.name || user.username || "U")}
                  </div>
                  <span class="rumbl-presence-dot is-online"></span>
                </div>
                <div class="min-w-0">
                  <p class="truncate text-sm font-semibold text-[#e8eeff]">{user.name}</p>
                  <p class="truncate text-xs text-[#8e9ab7]">{Enum.join(user.rings, ", ")}</p>
                </div>
                <span class="rumbl-presence-badge">APP</span>
              </.link>
            <% end %>
          </div>
        </section>

        <section id="presence-offline-global" class="rumbl-presence-section">
          <h3 class="rumbl-presence-heading">Offline — 0</h3>
          <div class="rumbl-active-now-card">
            <p class="text-xs text-[#7d879f]">Open a ring to view offline members.</p>
          </div>
        </section>
      <% end %>
    </aside>
    """
  end
end
