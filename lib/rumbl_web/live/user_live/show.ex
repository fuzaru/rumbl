defmodule RumblWeb.UserLive.Show do
  use RumblWeb, :live_view

  alias Rumbl.Accounts
  alias Rumbl.Rings

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    profile_user = Accounts.get_user!(id)
    current_user = socket.assigns.current_user

    if Rings.share_ring?(current_user, profile_user) do
      {:ok,
       socket
       |> assign(:page_title, profile_user.name)
       |> assign(:user, profile_user)
       |> assign(:is_self, current_user.id == profile_user.id)
       |> assign_profile_edit_state(profile_user)}
    else
      {:ok,
       socket
       |> put_flash(:error, "You can only view profiles of users in the same ring.")
       |> redirect(to: ~p"/rings")}
    end
  end

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    {:ok,
     socket
     |> assign(:page_title, "My Profile")
     |> assign(:user, current_user)
     |> assign(:is_self, true)
     |> assign_profile_edit_state(current_user)}
  end

  @impl true
  def handle_event("open_profile_edit_modal", %{"field" => field}, socket)
      when field in ["name", "username"] do
    if socket.assigns.is_self do
      {:noreply,
       socket
       |> assign(:profile_edit_modal_open, true)
       |> assign(:profile_edit_field, field)
       |> assign_profile_edit_form(socket.assigns.user, field)}
    else
      {:noreply, put_flash(socket, :error, "You can only edit your own profile.")}
    end
  end

  def handle_event("close_profile_edit_modal", _params, socket) do
    {:noreply, assign(socket, :profile_edit_modal_open, false)}
  end

  def handle_event("validate_profile_field", %{"profile" => profile_params}, socket) do
    if socket.assigns.is_self do
      edited_field = socket.assigns.profile_edit_field
      edited_value = Map.get(profile_params, edited_field, "")
      field_params = %{edited_field => edited_value}

      changeset =
        socket.assigns.user
        |> Accounts.change_user(field_params)
        |> Map.put(:action, :validate)

      {:noreply, assign(socket, :profile_edit_form, to_form(changeset, as: :profile))}
    else
      {:noreply, put_flash(socket, :error, "You can only edit your own profile.")}
    end
  end

  def handle_event("save_profile_field", %{"profile" => profile_params}, socket) do
    if socket.assigns.is_self do
      edited_field = socket.assigns.profile_edit_field
      edited_value = Map.get(profile_params, edited_field, "")
      field_params = %{edited_field => edited_value}

      case Accounts.update_user(socket.assigns.user, field_params) do
        {:ok, user} ->
          {:noreply,
           socket
           |> assign(:user, user)
           |> assign(:current_user, user)
           |> assign(:page_title, user.name)
           |> assign_profile_edit_state(user)
           |> put_flash(:info, "Profile updated successfully.")}

        {:error, changeset} ->
          {:noreply,
           assign(
             socket,
             :profile_edit_form,
             to_form(Map.put(changeset, :action, :validate), as: :profile)
           )}
      end
    else
      {:noreply, put_flash(socket, :error, "You can only edit your own profile.")}
    end
  end

  def handle_event("delete_account", _params, socket) do
    if socket.assigns.is_self do
      case Accounts.delete_user(socket.assigns.user) do
        {:ok, _user} ->
          {:noreply,
           socket
           |> put_flash(:info, "Account deleted successfully.")
           |> push_navigate(to: ~p"/")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Could not delete account.")}
      end
    else
      {:noreply, put_flash(socket, :error, "You can only edit your own profile.")}
    end
  end

  defp assign_profile_edit_state(socket, user) do
    socket
    |> assign(:profile_edit_modal_open, false)
    |> assign(:profile_edit_field, "name")
    |> assign_profile_edit_form(user, "name")
  end

  defp assign_profile_edit_form(socket, user, field) when field in ["name", "username"] do
    field_atom = String.to_existing_atom(field)

    form =
      user
      |> Accounts.change_user(%{field => Map.get(user, field_atom)})
      |> to_form(as: :profile)

    assign(socket, :profile_edit_form, form)
  end
end
