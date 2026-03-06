defmodule RumblWeb.SessionControllerTest do
  use RumblWeb.ConnCase, async: true

  import Rumbl.TestFixtures

  test "POST /sessions logs in with valid credentials", %{conn: conn} do
    user = user_fixture()

    conn =
      post(conn, ~p"/sessions", %{
        "session" => %{"username" => user.username, "password" => "supersecret123"}
      })

    assert redirected_to(conn) == "/rings"
    assert get_session(conn, :user_id) == user.id
  end

  test "POST /sessions redirects back on invalid credentials", %{conn: conn} do
    user = user_fixture()

    conn =
      post(conn, ~p"/sessions", %{
        "session" => %{"username" => user.username, "password" => "wrong-pass"}
      })

    assert redirected_to(conn) == "/sessions/new"
  end

  test "DELETE /sessions logs out current user", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)

    conn = delete(conn, ~p"/sessions")

    assert redirected_to(conn) == "/"
  end
end
