defmodule DevpulseServer.Onboarding.DeveloperInvite do
  use Ash.Resource,
    domain: DevpulseServer.Onboarding,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("developer_invites")
    repo(DevpulseServer.Core.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :email, :string do
      allow_nil?(false)
    end

    attribute :token, :string do
      allow_nil?(false)
    end

    attribute :status, :atom do
      constraints(one_of: [:pending, :accepted, :expired])
      default(:pending)
    end

    attribute(:expires_at, :utc_datetime)
  end

  relationships do
    belongs_to(:team, DevpulseServer.Teams.Team)
  end

  actions do
    defaults([:read, :update, :destroy])

    create :invite_developer do
      accept([:email])
      argument(:team_id, :uuid, allow_nil?: false)

      change(fn changeset, _context ->
        team_id = Ash.Changeset.get_argument(changeset, :team_id)

        invite_token = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
        seven_days_from_now = DateTime.utc_now() |> DateTime.add(7, :day)

        changeset
        |> Ash.Changeset.change_attribute(:team_id, team_id)
        |> Ash.Changeset.change_attribute(:token, invite_token)
        |> Ash.Changeset.change_attribute(:expires_at, seven_days_from_now)
        |> Ash.Changeset.change_attribute(:status, :pending)
      end)
    end
  end
end
