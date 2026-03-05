defmodule RumblWeb.RingLive.Index.CategoryManagement do
  import Phoenix.Component, only: [assign: 3, to_form: 2]

  alias Rumbl.Multimedia

  def init_assigns(socket) do
    socket
    |> refresh_category_assigns()
    |> assign(:create_category_modal_open, false)
    |> assign(:create_category_form, to_form(category_changeset(%{}), as: :category))
    |> assign(:delete_category_modal_open, false)
    |> assign(:delete_category_form, to_form(%{"category_id" => ""}, as: :delete_category))
  end

  def open_create_modal(socket) do
    socket
    |> assign(:create_category_modal_open, true)
    |> assign(:create_category_form, to_form(category_changeset(%{}), as: :category))
  end

  def close_create_modal(socket), do: assign(socket, :create_category_modal_open, false)

  def validate_create_modal(socket, category_params) do
    changeset =
      category_params
      |> normalize_name_params()
      |> category_changeset()
      |> Map.put(:action, :validate)

    assign(socket, :create_category_form, to_form(changeset, as: :category))
  end

  def save_category(socket, category_params) do
    normalized_params = normalize_name_params(category_params)
    changeset = category_changeset(normalized_params)

    if changeset.valid? do
      case Multimedia.create_category(normalized_params) do
        {:ok, _category} ->
          {:noreply,
           socket
           |> refresh_category_assigns()
           |> assign(:create_category_modal_open, false)
           |> assign(:create_category_form, to_form(category_changeset(%{}), as: :category))
           |> Phoenix.LiveView.put_flash(:info, "Category created successfully.")}

        {:error, %Ecto.Changeset{} = create_changeset} ->
          {:noreply,
           assign(
             socket,
             :create_category_form,
             to_form(Map.put(create_changeset, :action, :validate), as: :category)
           )}
      end
    else
      {:noreply,
       assign(
         socket,
         :create_category_form,
         to_form(Map.put(changeset, :action, :validate), as: :category)
       )}
    end
  end

  def open_delete_modal(socket) do
    selected_id =
      case socket.assigns.all_categories do
        [%{id: id} | _] -> to_string(id)
        _ -> ""
      end

    socket
    |> assign(:delete_category_modal_open, true)
    |> assign(
      :delete_category_form,
      to_form(%{"category_id" => selected_id}, as: :delete_category)
    )
  end

  def close_delete_modal(socket), do: assign(socket, :delete_category_modal_open, false)

  def validate_delete_modal(socket, %{"category_id" => category_id}) do
    assign(
      socket,
      :delete_category_form,
      to_form(%{"category_id" => category_id}, as: :delete_category)
    )
  end

  def delete_selected_category(socket, %{"category_id" => category_id}) do
    case category_id do
      "" ->
        {:noreply, Phoenix.LiveView.put_flash(socket, :error, "Choose a category to delete.")}

      _ ->
        delete_category(socket, category_id)
    end
  end

  def delete_category(socket, category_id) do
    category = Multimedia.get_category!(category_id)

    case Multimedia.delete_category(category) do
      {:ok, _category} ->
        {:noreply,
         socket
         |> refresh_category_assigns()
         |> assign(:delete_category_modal_open, false)
         |> Phoenix.LiveView.put_flash(:info, "Category deleted successfully.")}

      {:error, _changeset} ->
        {:noreply, Phoenix.LiveView.put_flash(socket, :error, "Could not delete category.")}
    end
  rescue
    Ecto.NoResultsError ->
      {:noreply, Phoenix.LiveView.put_flash(socket, :error, "Category not found.")}
  end

  defp refresh_category_assigns(socket) do
    categories = Multimedia.list_categories()

    socket
    |> assign(:all_categories, categories)
    |> assign(:categories, Enum.map(categories, &{&1.name, &1.id}))
  end

  defp category_changeset(params) do
    types = %{name: :string}

    {%{}, types}
    |> Ecto.Changeset.cast(params, [:name])
    |> Ecto.Changeset.validate_required([:name])
    |> Ecto.Changeset.validate_length(:name, min: 2, max: 50)
  end

  defp normalize_name_params(params) do
    Map.update(params, "name", "", &String.trim/1)
  end
end
