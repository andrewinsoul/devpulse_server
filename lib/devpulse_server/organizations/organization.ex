defmodule DevpulseServer.Organizations.Organization do
  use Ash.Resource,
    domain: DevpulseServer.Organizations,
    data_layer: AshPostgres.DataLayer

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

  relationships do
    belongs_to :user, DevpulseServer.Accounts.User do
      allow_nil?(false)
    end

    has_many(:teams, DevpulseServer.Teams.Team)
  end

  actions do
    defaults([:create, :read, :update, :destroy])
  end
end
