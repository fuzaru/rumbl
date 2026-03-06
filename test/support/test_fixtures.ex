defmodule Rumbl.TestFixtures do
  @moduledoc false

  import Phoenix.ConnTest, only: [init_test_session: 2]

  alias Rumbl.Accounts
  alias Rumbl.Multimedia
  alias Rumbl.Rings

  def unique_username, do: "user#{System.unique_integer([:positive])}"
  def unique_name, do: "User #{System.unique_integer([:positive])}"
  def unique_ring_name, do: "Ring #{System.unique_integer([:positive])}"

  def user_fixture(attrs \\ %{}) do
    attrs =
      Map.merge(
        %{
          "name" => unique_name(),
          "username" => unique_username(),
          "password" => "supersecret123"
        },
        attrs
      )

    {:ok, user} = Accounts.register_user(attrs)
    user
  end

  def ring_fixture(owner, attrs \\ %{}) do
    attrs = Map.merge(%{"name" => unique_ring_name()}, attrs)
    {:ok, ring} = Rings.create_ring(owner, attrs)
    ring
  end

  def video_fixture(user, ring, attrs \\ %{}) do
    attrs =
      Map.merge(
        %{
          "title" => "Video #{System.unique_integer([:positive])}",
          "url" => "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
          "description" => "Test video",
          "ring_id" => ring.id
        },
        attrs
      )

    {:ok, video} = Multimedia.create_video(user, attrs)
    Multimedia.get_video!(video.slug)
  end

  def annotation_fixture(user, video, attrs \\ %{}) do
    attrs =
      Map.merge(
        %{
          "at" => 30_000,
          "body" => "annotation-#{System.unique_integer([:positive])}"
        },
        attrs
      )

    {:ok, annotation} = Multimedia.annotate_video(user, video.id, attrs)
    annotation
  end

  def log_in_user(conn, user) do
    init_test_session(conn, user_id: user.id)
  end
end
