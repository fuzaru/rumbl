defmodule RumblWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use RumblWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_user, :map, default: nil, doc: "the current logged in user"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :show_nav_border, :boolean, default: true, doc: "whether to show the navbar bottom border"
  attr :overlay_nav, :boolean, default: false, doc: "whether the navbar overlays the page content"

  attr :main_class, :string,
    default: "px-4 py-10 sm:px-6 lg:px-8",
    doc: "classes for the main wrapper"

  attr :content_class, :string,
    default: "mx-auto max-w-4xl space-y-4",
    doc: "classes for the inner content wrapper"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class={[
      "navbar px-4 sm:px-6 lg:px-8 bg-black/35 backdrop-blur-md",
      @overlay_nav && "absolute inset-x-0 top-0 z-30",
      @show_nav_border && "border-b border-base-300"
    ]}>
      <div class="flex-1">
        <a href="/" class="ml-8 md:ml-16 flex w-fit items-center gap-2">
          <span class="text-xl font-bold text-brand">Rumbl</span>
        </a>
      </div>
      <div class="flex-none">
        <ul class="flex flex-column px-1 space-x-4 items-center">
          <%= if @current_user do %>
            <li>
              <a href="/videos" class="btn btn-ghost">My Videos</a>
            </li>
            <li>
              <span class="text-sm">Hello, <strong>{@current_user.name}</strong></span>
            </li>
            <li>
              <a href={"/users/#{@current_user.id}"} class="btn btn-ghost btn-sm">Profile</a>
            </li>
            <li>
              <.link href="/sessions" method="delete" class="btn btn-ghost btn-sm">Log out</.link>
            </li>
          <% else %>
            <li>
              <a href="/sessions/new" class="btn btn-ghost">{gettext("Log in")}</a>
            </li>
            <li>
              <a href="/users/new" class="btn btn-primary">{gettext("Register")}</a>
            </li>
          <% end %>
          <li>
            <.locale_switcher />
          </li>
        </ul>
      </div>
    </header>

    <main class={@main_class}>
      <div class={@content_class}>
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides language switching for supported locales.
  """
  def locale_switcher(assigns) do
    assigns = assign(assigns, :current_locale, Gettext.get_locale(RumblWeb.Gettext))

    ~H"""
    <div class="flex items-center gap-2 rounded-full border border-base-300 bg-base-200/60 px-2 py-1 text-sm">
      <.link
        href={~p"/locale/en"}
        class={[
          "btn btn-xs rounded-full",
          if(@current_locale == "en", do: "btn-primary", else: "btn-ghost")
        ]}
      >
        {gettext("English")}
      </.link>
      <.link
        href={~p"/locale/fil"}
        class={[
          "btn btn-xs rounded-full",
          if(@current_locale == "fil", do: "btn-primary", else: "btn-ghost")
        ]}
      >
        {gettext("Filipino")}
      </.link>
    </div>
    """
  end
end
