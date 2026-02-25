defmodule RumblWeb.UserLive.Register do
  use RumblWeb, :live_view

  alias Rumbl.Accounts
  alias Rumbl.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    changeset = Accounts.change_registration(%User{})

    {:ok,
     socket
     |> assign(:page_title, "Register")
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> Accounts.change_registration(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Account created. Please log in.")
         |> push_navigate(to: ~p"/sessions/new")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
