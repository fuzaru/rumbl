defmodule RumblWeb.PageLive.LandingTest do
  use RumblWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Rumbl.TestFixtures

  test "unauthenticated user sees landing page", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, "a[href='/users/new']")
    assert has_element?(view, "a[href='/sessions/new']")
  end

  test "authenticated user is redirected to rings", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)

    assert {:error, {:redirect, %{to: "/rings"}}} = live(conn, ~p"/")
  end
end
