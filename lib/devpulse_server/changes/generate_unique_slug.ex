defmodule DevpulseServer.Changes.GenerateUniqueSlug do
  use Ash.Resource.Change
  alias Ash.Changeset

  def change(changeset, opts, _context) do
    source_field = opts[:look_at] || :name
    target_field = opts[:write_to] || :slug
    scope_field = opts[:scope]

    if Changeset.get_attribute(changeset, target_field) do
      changeset
    else
      case Changeset.get_attribute(changeset, source_field) do
        nil ->
          changeset

        source_value ->
          base_slug = slugify(source_value)
          unique_slug = find_unique_slug(changeset, target_field, base_slug, scope_field)
          Changeset.force_change_attribute(changeset, target_field, unique_slug)
      end
    end
  end

  defp slugify(string_val) when is_binary(string_val) do
    string_val
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/[\s-]+/, "-")
    |> String.trim("-")
  end

  defp slugify(_), do: ""

  defp find_unique_slug(changeset, target_field, slug, scope_field, counter \\ 0) do
    current_slug = if counter == 0, do: slug, else: "#{slug}-#{counter}"

    query = Ash.Query.filter(changeset.resource, ^[{target_field, current_slug}])

    query =
      if scope_field do
        scope_value =
          Changeset.get_attribute(changeset, scope_field) ||
            Changeset.get_argument(changeset, scope_field)

        Ash.Query.filter(query, ^[{scope_field, scope_value}])
      else
        query
      end

    case Ash.read_one(query) do
      {:ok, nil} ->
        current_slug

      _ ->
        find_unique_slug(changeset, target_field, slug, scope_field, counter + 1)
    end
  end
end
