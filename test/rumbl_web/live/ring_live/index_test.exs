defmodule RumblWeb.RingLive.IndexTest do
  use RumblWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Rumbl.TestFixtures

  test "redirects unauthenticated users to login", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/sessions/new"}}} = live(conn, ~p"/rings")
  end

  test "shows my rings view for authenticated users", %{conn: conn} do
    user = user_fixture()
    _ring = ring_fixture(user)
    conn = log_in_user(conn, user)

    {:ok, view, _html} = live(conn, ~p"/rings")

    assert has_element?(view, "#my-rings-section")
    assert has_element?(view, "#rings-new-button")
  end

  test "shows ring workspace when opening a ring", %{conn: conn} do
    user = user_fixture()
    ring = ring_fixture(user)
    _video = video_fixture(user, ring)
    conn = log_in_user(conn, user)

    {:ok, view, _html} = live(conn, ~p"/rings/#{ring.id}")

    assert has_element?(view, "#ring-workspace-section")
    assert has_element?(view, "#ring-selected-video")
    assert has_element?(view, "#video-annotations")
  end

  test "expands selected annotation details when clicking an annotation", %{conn: conn} do
    user = user_fixture()
    ring = ring_fixture(user)
    video = video_fixture(user, ring)
    annotation = annotation_fixture(user, video)
    conn = log_in_user(conn, user)

    {:ok, view, _html} = live(conn, ~p"/rings/#{ring.id}")

    assert has_element?(view, ".rumbl-annotation-expand")

    view
    |> element("#annotation-#{annotation.id}")
    |> render_click()

    assert has_element?(view, ".rumbl-annotation-expand.is-open")
    assert has_element?(view, ".rumbl-annotation-expand-body")
  end

  test "shows invitation requests panel route", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)

    {:ok, view, _html} = live(conn, ~p"/invitations")

    assert has_element?(view, "#invitation-requests-section")
    assert has_element?(view, "#invite-user-section")
  end
end
