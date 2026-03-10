defmodule RumblWeb.UserLive.ShowTest do
  use RumblWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Rumbl.TestFixtures
  alias Rumbl.Accounts

  test "shows profile page for authenticated user", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)

    {:ok, view, _html} = live(conn, ~p"/user")

    assert has_element?(view, "#user-profile-card")
    assert has_element?(view, "#edit-display-name")
  end

  test "opens profile edit modal from edit button", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)
    {:ok, view, _html} = live(conn, ~p"/user")

    view
    |> element("#edit-display-name")
    |> render_click()

    assert has_element?(view, "#profile-edit-modal")
    assert has_element?(view, "#profile-edit-form")
  end

  test "self user can delete account from profile", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)
    {:ok, view, _html} = live(conn, ~p"/user")

    assert has_element?(view, "#delete-account")

    view
    |> element("#delete-account")
    |> render_click()

    assert_redirect(view, ~p"/")
    assert Accounts.get_user(user.id) == nil
  end
end
