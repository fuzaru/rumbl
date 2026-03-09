defmodule RumblWeb.VideoLive.IndexTest do
  use RumblWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Rumbl.TestFixtures

  test "redirects unauthenticated users to login", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/sessions/new"}}} = live(conn, ~p"/videos")
  end

  test "renders videos workspace for authenticated users", %{conn: conn} do
    user = user_fixture()
    ring = ring_fixture(user)
    _video = video_fixture(user, ring)
    conn = log_in_user(conn, user)

    {:ok, view, _html} = live(conn, ~p"/videos")

    assert has_element?(view, "#my-videos-section")
    assert has_element?(view, "#videos-add-button")
    assert has_element?(view, "#videos-panel-my-videos")
    assert has_element?(view, ".rumbl-main.is-active-now-collapsed")
  end
end
