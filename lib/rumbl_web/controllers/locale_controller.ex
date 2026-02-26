defmodule RumblWeb.LocaleController do
  use RumblWeb, :controller

  alias RumblWeb.Locale

  def update(conn, %{"locale" => locale}) do
    conn = Locale.put_locale(conn, locale)
    redirect_to = redirect_path_from_referer(List.first(get_req_header(conn, "referer")))

    redirect(conn, to: redirect_to)
  end

  defp redirect_path_from_referer(nil), do: ~p"/"

  defp redirect_path_from_referer(referer) do
    uri = URI.parse(referer)
    path = uri.path || "/"

    case uri.query do
      nil -> path
      query -> path <> "?" <> query
    end
  end
end
