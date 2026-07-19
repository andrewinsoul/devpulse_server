defmodule DevpulseServer.Teams.Team do
  use Ash.Resource,
    domain: DevpulseServer.Teams,
    data_layer: AshPostgres.DataLayer

  alias DevpulseServer.Changes.GenerateUniqueSlug

  postgres do
    table("teams")
    repo(DevpulseServer.Core.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute(:slug, :string, allow_nil?: false, public?: true)
  end

  identities do
    identity(:unique_slug, [:organization_id, :slug])
  end

  relationships do
    belongs_to(:organization, DevpulseServer.Organizations.Organization) do
      allow_nil?(false)
    end

    has_many(:developers, DevpulseServer.Onboarding.DeveloperInvite)

    many_to_many :developer_profiles, DevpulseServer.Identity.DeveloperProfile do
      through(DevpulseServer.Teams.Membership)

      source_attribute_on_join_resource(:team_id)
      destination_attribute_on_join_resource(:developer_profile_id)
    end

    has_many(:team_memberships, DevpulseServer.Teams.Membership)
    has_many(:projects, DevpulseServer.Teams.Project)
  end

  actions do
    default_accept(:*)
    defaults([:read, :update, :destroy])

    create :create_team do
      accept([:name, :slug])

      argument(:organization_id, :uuid, allow_nil?: false)
      change(manage_relationship(:organization_id, :organization, type: :append_and_remove))

      change({GenerateUniqueSlug, scope: :organization_id})
    end
  end
end
