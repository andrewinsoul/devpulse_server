defmodule DevpulseServer.Identity.DeveloperProfile do
  require Ash.Query

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
      argument(:invite_token, :string, allow_nil?: false)
      accept([:name, :avatar_url])

      transaction?(true)

      change(fn changeset, _context ->
        Ash.Changeset.before_action(changeset, fn changeset ->
          invite_token = Ash.Changeset.get_argument(changeset, :invite_token)

          case DevpulseServer.Onboarding.DeveloperInvite
               |> Ash.Query.for_read(:read, %{})
               |> Ash.Query.filter(expr(token == ^invite_token and status == :pending))
               |> Ash.read_one() do
            {:ok, %{team_id: team_id, expires_at: expires_at} = invite} ->
              now = DateTime.utc_now()

              if expires_at && DateTime.compare(now, expires_at) == :gt do
                Ash.update!(invite, [{:status, :expired}])
                Ash.Changeset.add_error(changeset, "This invitation token has expired.")
              else
                Ash.update!(invite, [{:status, :accepted}])

                changeset
                |> Ash.Changeset.change_attribute(:email, invite.email)
                |> Ash.Changeset.manage_relationship(:invite, invite, type: :append)
                |> Ash.Changeset.after_action(fn _changeset, profile ->
                  {:ok, _membership} =
                    DevpulseServer.Teams.Membership
                    |> Ash.Changeset.for_create(:join_team, %{
                      team_id: team_id,
                      developer_profile_id: profile.id
                    })
                    |> Ash.create()

                  {:ok, api_token} =
                    DevpulseServer.Agents.ApiToken
                    |> Ash.Changeset.for_create(:generate_for_developer, %{
                      developer_profile_id: profile.id
                    })
                    |> Ash.create()

                  raw_token = api_token.meta[:raw_token]
                  {:ok, Ash.Resource.put_metadata(profile, :raw_token, raw_token)}
                end)
              end

            _ ->
              Ash.Changeset.add_error(changeset, "Invalid or expired invitation token.")
          end
        end)
      end)
    end
  end
end
