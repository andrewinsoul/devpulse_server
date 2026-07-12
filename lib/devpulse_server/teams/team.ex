defmodule DevpulseServer.Teams.Team do
  use Ash.Resource,
    domain: DevpulseServer.Teams,
    data_layer: AshPostgres.DataLayer

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
    identity(:unique_slug, [:slug])
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

      change(fn changeset, _context ->
        case Ash.Changeset.get_attribute(changeset, :slug) do
          nil ->
            if name = Ash.Changeset.get_attribute(changeset, :name) do
              base_slug =
                name
                |> String.downcase()
                |> String.replace(~r/[^a-z0-9\s-]/, "")
                |> String.replace(~r/[\s-]+/, "-")
                |> String.trim("-")

              timestamp = System.system_time(:second)
              final_slug = "#{base_slug}-#{timestamp}"

              Ash.Changeset.change_attribute(changeset, :slug, final_slug)
            else
              changeset
            end

          _already_set ->
            changeset
        end
      end)
    end
  end
end
