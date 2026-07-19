defmodule DevpulseServer.Organizations.Organization do
  use Ash.Resource,
    domain: DevpulseServer.Organizations,
    data_layer: AshPostgres.DataLayer

  alias DevpulseServer.Changes.GenerateUniqueSlug

  postgres do
    table("organizations")
    repo(DevpulseServer.Core.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
    end

    attribute :slug, :string do
      allow_nil?(false)
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  identities do
    identity(:unique_slug, [:slug])
  end

  relationships do
    belongs_to :user, DevpulseServer.Accounts.User do
      allow_nil?(false)
    end

    has_many(:teams, DevpulseServer.Teams.Team)
  end

  actions do
    defaults([:read, :update, :destroy])

    create :create do
      accept([:name, :slug])

      argument(:user_id, :uuid, allow_nil?: false)
      change(manage_relationship(:user_id, :user, type: :append_and_remove))

      change(GenerateUniqueSlug)
    end
  end
end
