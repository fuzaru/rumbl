defmodule RumblWeb.RingLive.IndexTest do
  use RumblWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Rumbl.TestFixtures

  alias Rumbl.Rings

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

  test "shows annotation preview modal when clicking an annotation", %{conn: conn} do
    user = user_fixture()
    ring = ring_fixture(user)
    video = video_fixture(user, ring)
    annotation = annotation_fixture(user, video)
    conn = log_in_user(conn, user)

    {:ok, view, _html} = live(conn, ~p"/rings/#{ring.id}")

    refute has_element?(view, "#annotation-preview-modal")

    view
    |> element("#annotation-#{annotation.id}")
    |> render_click()

    assert has_element?(view, "#annotation-preview-modal")

    view
    |> element("#annotation-preview-modal-close")
    |> render_click()

    refute has_element?(view, "#annotation-preview-modal")
  end

  test "keeps timestamp while typing annotation message", %{conn: conn} do
    user = user_fixture()
    ring = ring_fixture(user)
    _video = video_fixture(user, ring)
    conn = log_in_user(conn, user)

    {:ok, view, _html} = live(conn, ~p"/rings/#{ring.id}")

    view
    |> form("#annotation-form", %{"annotation" => %{"at" => "1:23", "body" => "hello"}})
    |> render_change()

    assert has_element?(view, "#annotation-form input[name='annotation[at]'][value='1:23']")
  end

  test "filters annotations by timeline timestamp and clears filter", %{conn: conn} do
    user = user_fixture()
    ring = ring_fixture(user)
    video = video_fixture(user, ring)
    annotation_a = annotation_fixture(user, video, %{"at" => 30_000, "body" => "A"})
    annotation_b = annotation_fixture(user, video, %{"at" => 30_000, "body" => "B"})
    annotation_c = annotation_fixture(user, video, %{"at" => 45_000, "body" => "C"})
    conn = log_in_user(conn, user)

    {:ok, view, _html} = live(conn, ~p"/rings/#{ring.id}")

    assert has_element?(view, "#annotation-#{annotation_a.id}")
    assert has_element?(view, "#annotation-#{annotation_b.id}")
    assert has_element?(view, "#annotation-#{annotation_c.id}")

    view
    |> element("#timeline-marker-30000")
    |> render_click()

    assert has_element?(view, "#annotation-#{annotation_a.id}")
    assert has_element?(view, "#annotation-#{annotation_b.id}")
    refute has_element?(view, "#annotation-#{annotation_c.id}")
    assert has_element?(view, "#annotation-filter-clear")

    view
    |> element("#annotation-filter-clear")
    |> render_click()

    assert has_element?(view, "#annotation-#{annotation_c.id}")
  end

  test "deletes own annotation from ring workspace", %{conn: conn} do
    user = user_fixture()
    ring = ring_fixture(user)
    video = video_fixture(user, ring)
    annotation = annotation_fixture(user, video)
    conn = log_in_user(conn, user)

    {:ok, view, _html} = live(conn, ~p"/rings/#{ring.id}")

    assert has_element?(view, "#annotation-#{annotation.id}")
    assert has_element?(view, "#annotation-delete-#{annotation.id}")

    view
    |> element("#annotation-delete-#{annotation.id}")
    |> render_click()

    refute has_element?(view, "#annotation-#{annotation.id}")
  end

  test "hides annotation delete control for annotations owned by others", %{conn: conn} do
    user = user_fixture()
    other_user = user_fixture()
    ring = ring_fixture(user)
    video = video_fixture(user, ring)
    annotation = annotation_fixture(other_user, video)
    conn = log_in_user(conn, user)

    {:ok, view, _html} = live(conn, ~p"/rings/#{ring.id}")

    assert has_element?(view, "#annotation-#{annotation.id}")
    refute has_element?(view, "#annotation-delete-#{annotation.id}")
  end

  test "searches for a specific annotation from active now", %{conn: conn} do
    user = user_fixture()
    ring = ring_fixture(user)
    video = video_fixture(user, ring)
    annotation = annotation_fixture(user, video, %{"body" => "Need this exact cue"})
    _other_annotation = annotation_fixture(user, video, %{"body" => "Different note"})
    conn = log_in_user(conn, user)

    {:ok, view, _html} = live(conn, ~p"/rings/#{ring.id}")

    view
    |> element("#ring-active-now-search-toggle")
    |> render_click()

    assert has_element?(view, "#annotation-search-modal")

    view
    |> form("#annotation-search-form-modal", %{"annotation_search" => %{"query" => "exact cue"}})
    |> render_change()

    assert has_element?(view, "#annotation-search-result-#{annotation.id}")

    view
    |> element("#annotation-search-result-#{annotation.id}")
    |> render_click()

    assert has_element?(view, "#annotation-preview-modal")
    refute has_element?(view, "#annotation-search-modal")
  end

  test "shows invitation requests panel route", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)

    {:ok, view, _html} = live(conn, ~p"/invitations")

    assert has_element?(view, "#invitation-requests-section")
    assert has_element?(view, "#invite-user-section")
  end

  test "owner can delete ring from workspace dropdown", %{conn: conn} do
    user = user_fixture()
    ring = ring_fixture(user)
    conn = log_in_user(conn, user)

    {:ok, view, _html} = live(conn, ~p"/rings/#{ring.id}")

    assert has_element?(view, "#ring-delete-trigger")

    view
    |> element("#ring-delete-trigger")
    |> render_click()

    assert_redirect(view, ~p"/rings")
    assert Rings.list_user_rings(user) == []
  end

  test "non-owner does not see ring delete action", %{conn: conn} do
    owner = user_fixture()
    member = user_fixture()
    ring = ring_fixture(owner)
    {:ok, _} = Rings.join_ring_by_invite(member, ring.invite_code)
    conn = log_in_user(conn, member)

    {:ok, view, _html} = live(conn, ~p"/rings/#{ring.id}")

    refute has_element?(view, "#ring-delete-trigger")
  end

  test "annotation updates are reflected in another user's ring workspace", %{conn: conn} do
    owner = user_fixture()
    member = user_fixture()
    ring = ring_fixture(owner)
    {:ok, _membership} = Rings.join_ring_by_invite(member, ring.invite_code)
    _video = video_fixture(owner, ring)

    owner_conn = log_in_user(conn, owner)
    member_conn = log_in_user(build_conn(), member)

    {:ok, owner_view, _html} = live(owner_conn, ~p"/rings/#{ring.id}")
    {:ok, member_view, _html} = live(member_conn, ~p"/rings/#{ring.id}")

    refute has_element?(member_view, "#video-annotations .rumbl-annotation-row")

    owner_view
    |> form("#annotation-form", %{"annotation" => %{"at" => "0:30", "body" => "sync now"}})
    |> render_submit()

    _ = :sys.get_state(member_view.pid)

    assert has_element?(member_view, "#video-annotations .rumbl-annotation-row")
  end
end
