defmodule RumblWeb.PageControllerTest do
  use RumblWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Welcome to Rumbl"
  end
end
