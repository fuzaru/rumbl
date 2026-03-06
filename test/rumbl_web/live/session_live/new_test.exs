defmodule RumblWeb.SessionLive.NewTest do
  use RumblWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders login form with key actions", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/sessions/new")

    assert has_element?(view, "#session-form")
    assert has_element?(view, "#switch-to-register")
  end
end
