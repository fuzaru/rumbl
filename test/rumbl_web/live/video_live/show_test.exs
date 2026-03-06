defmodule RumblWeb.VideoLive.ShowTest do
  use RumblWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Rumbl.TestFixtures

  test "shows video details page", %{conn: conn} do
    user = user_fixture()
    ring = ring_fixture(user)
    video = video_fixture(user, ring)
    conn = log_in_user(conn, user)

    {:ok, view, _html} = live(conn, ~p"/videos/#{video.slug}")

    assert has_element?(view, "a[href='/videos']")
    assert has_element?(view, "a[target='_blank']")
  end
end
