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
    %URI{path: path, query: query} = URI.parse(referer)
    base = path || "/"
    if query, do: base <> "?" <> query, else: base
  end
end
