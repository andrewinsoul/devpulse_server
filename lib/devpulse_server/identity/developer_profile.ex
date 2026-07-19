defmodule DevpulseServer.Identity.DeveloperProfile do
  alias DevpulseServer.Agents.ApiToken
  alias DevpulseServer.Teams.Membership

  use Ash.Resource,
    domain: DevpulseServer.Identity,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("developer_profiles")
    repo(DevpulseServer.Core.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
    end

    attribute :email, :string do
      allow_nil?(false)
    end

    attribute(:avatar_url, :string)

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  identities do
    identity(:unique_email, [:email])
  end

  relationships do
    belongs_to(:invite, DevpulseServer.Onboarding.DeveloperInvite)

    has_many(:agent_sessions, DevpulseServer.Agents.AgentSession)
    has_many(:team_memberships, DevpulseServer.Teams.Membership)
  end

  actions do
    defaults([:read, :update, :destroy])

    create :create_from_invite do
      accept([:name, :avatar_url, :email])

      argument(:invite_id, :uuid, allow_nil?: false)
      argument(:team_id, :uuid, allow_nil?: false)

      # Links the profile to the invite row
      change(manage_relationship(:invite_id, :invite, type: :append))

      change(fn changeset, _context ->
        Ash.Changeset.after_action(changeset, fn changeset, profile ->
          team_id = Ash.Changeset.get_argument(changeset, :team_id)

          {:ok, _membership} =
            Membership
            |> Ash.Changeset.for_create(:join_team, %{
              team_id: team_id,
              developer_profile_id: profile.id
            })
            |> Ash.create()

          [before, _after] = String.split(profile.email, "@")

          {:ok, cli_token} =
            ApiToken
            |> Ash.Changeset.for_create(:generate_for_developer, %{
              developer_profile_id: profile.id,
              name: profile.name <> " #{before}"
            })
            |> Ash.create()

          raw_token =
            Ash.Resource.get_metadata(cli_token, :raw_token) || Map.get(cli_token, :token)

          {:ok, Ash.Resource.put_metadata(profile, :raw_token, raw_token)}
        end)
      end)
    end
  end
end
