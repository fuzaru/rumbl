defmodule RumblWeb.LocaleControllerTest do
  use RumblWeb.ConnCase, async: true

  test "GET /locale/:locale stores locale and returns to referer path", %{conn: conn} do
    conn =
      conn
      |> put_req_header("referer", "http://localhost:4002/videos?modal=new")
      |> get(~p"/locale/fil")

    assert redirected_to(conn) == "/videos?modal=new"
    assert get_session(conn, :locale) == "fil"
  end

  test "GET /locale/:locale falls back to root when referer is missing", %{conn: conn} do
    conn = get(conn, ~p"/locale/en")

    assert redirected_to(conn) == "/"
    assert get_session(conn, :locale) == "en"
  end
end
