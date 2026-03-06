defmodule RumblWeb.UserLive.RegisterTest do
  use RumblWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Rumbl.TestFixtures

  test "renders register form", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/users/new")

    assert has_element?(view, "#user-register-form")
    assert has_element?(view, "#switch-to-login")
  end

  test "submitting valid form navigates to login", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/users/new")

    params = %{
      "user" => %{
        "name" => "Test User",
        "username" => unique_username(),
        "password" => "supersecret123"
      }
    }

    assert {:error, {:live_redirect, %{to: "/sessions/new"}}} =
             view
             |> form("#user-register-form", params)
             |> render_submit()
  end
end
