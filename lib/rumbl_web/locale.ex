defmodule RumblWeb.Locale do
  @moduledoc """
  Locale helpers for request/session and LiveView usage.
  """

  import Plug.Conn

  @supported_locales ~w(en fil)

  def init(opts), do: opts

  def call(conn, _opts) do
    locale = current_locale(conn)

    Gettext.put_locale(RumblWeb.Gettext, locale)

    assign(conn, :locale, locale)
  end

  def put_locale(conn, locale) do
    locale = normalize_locale(locale)

    conn
    |> put_session(:locale, locale)
    |> assign(:locale, locale)
  end

  def from_session(session) when is_map(session) do
    normalize_locale(Map.get(session, "locale") || Map.get(session, :locale))
  end

  defp current_locale(conn) do
    conn
    |> get_session(:locale)
    |> normalize_locale()
  end

  defp normalize_locale(locale) when locale in @supported_locales, do: locale
  defp normalize_locale(_), do: "en"
end
