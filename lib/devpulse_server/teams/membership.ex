defmodule DevpulseServer.Teams.Membership do
  use Ash.Resource,
    domain: DevpulseServer.Teams,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("team_memberships")
    repo(DevpulseServer.Core.Repo)
  end

  attributes do
    uuid_primary_key(:id)
  end

  relationships do
    belongs_to(:team, DevpulseServer.Teams.Team) do
      allow_nil?(false)
      attribute_public?(true)
    end

    belongs_to(:developer_profile, DevpulseServer.Identity.DeveloperProfile) do
      allow_nil?(false)
      attribute_public?(true)
    end
  end

  identities do
    identity(:unique_team_membership, [:team_id, :developer_profile_id])
  end

  actions do
    defaults([:read, :update, :destroy])

    create :join_team do
      argument(:team_id, :uuid, allow_nil?: false)
      argument(:developer_profile_id, :uuid, allow_nil?: false)

      change(fn changeset, _context ->
        changeset
        |> Ash.Changeset.change_attribute(:team_id, Ash.Changeset.get_argument(changeset, :team_id))
        |> Ash.Changeset.change_attribute(
          :developer_profile_id,
          Ash.Changeset.get_argument(changeset, :developer_profile_id)
        )
      end)
    end
  end
end
