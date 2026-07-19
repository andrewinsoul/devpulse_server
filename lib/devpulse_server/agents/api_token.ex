defmodule DevpulseServer.Agents.ApiToken do
  use Ash.Resource,
    domain: DevpulseServer.Agents,
    data_layer: AshPostgres.DataLayer

  defp hash_token(token) when is_binary(token) do
    :crypto.hash(:sha256, token) |> Base.encode16(case: :lower)
  end

  postgres do
    table("api_tokens")
    repo(DevpulseServer.Core.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :token_hash, :string do
      allow_nil?(false)
      sensitive?(true)
    end

    attribute(:name, :string)

    attribute(:last_used_at, :utc_datetime)

    attribute(:revoked_at, :utc_datetime)
  end

  relationships do
    belongs_to(:developer_profile, DevpulseServer.Identity.DeveloperProfile)
  end

  actions do
    defaults([:destroy])

    read :read do
      primary?(true)
    end

    create :generate_for_developer do
      accept([:name])

      argument(:developer_profile_id, :uuid, allow_nil?: false)

      change(fn changeset, _context ->
        dev_profile_id = Ash.Changeset.get_argument(changeset, :developer_profile_id)

        case Ash.get(DevpulseServer.Identity.DeveloperProfile, dev_profile_id) do
          {:ok, profile} ->
            safe_name =
              profile.name
              |> String.downcase()
              |> String.replace(~r/[^a-z0-9-]/, "-")
              |> String.replace(~r/-+/, "-")
              |> String.trim("-")

            safe_name = if safe_name == "", do: "dev", else: safe_name

            random_bytes = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
            raw_token = "dp_pat_#{safe_name}_#{random_bytes}"
            hash = hash_token(raw_token)

            changeset
            |> Ash.Changeset.change_attribute(:developer_profile_id, dev_profile_id)
            |> Ash.Changeset.change_attribute(:token_hash, hash)
            |> Ash.Changeset.after_action(fn _changeset, api_token ->
              {:ok, Ash.Resource.put_metadata(api_token, :raw_token, raw_token)}
            end)

          {:error, _reason} ->
            Ash.Changeset.add_error(changeset,
              field: :developer_profile_id,
              message: "Developer profile not found"
            )
        end
      end)
    end

    read :verify_token do
      argument(:token, :string, allow_nil?: false)

      filter(expr(token_hash == fragment("encode(digest(?, 'sha256'), 'hex')", arg(:token))))
    end
  end
end
