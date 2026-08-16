defmodule DevpulseServer.Activity.Heartbeat do
  use Ash.Resource,
    domain: DevpulseServer.Activity,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("heartbeats")
    repo(DevpulseServer.Core.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :project_name, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :branch, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :repo_path, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :has_changes, :boolean do
      allow_nil?(false)
      public?(true)
    end

    create_timestamp(:inserted_at)
  end

  relationships do
    belongs_to :session, DevpulseServer.Agents.AgentSession do
      allow_nil?(false)
      attribute_writable?(true)
    end

    belongs_to :project, DevpulseServer.Teams.Project do
      allow_nil?(false)
      attribute_writable?(true)
    end
  end

  actions do
    defaults([:read])

    create :ping do
      accept([
        :project_name,
        :branch,
        :repo_path,
        :has_changes,
        :session_id,
        :project_id
      ])
    end
  end
end
