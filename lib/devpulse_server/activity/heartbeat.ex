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

    attribute(:project_name, :string) do
      public?(true)
    end

    attribute(:branch, :string) do
      public?(true)
    end

    attribute(:repo_path, :string) do
      public?(true)
    end

    attribute(:has_changes, :boolean) do
      public?(true)
    end

    create_timestamp(:inserted_at)
  end

  relationships do
    belongs_to(:session, DevpulseServer.Agents.AgentSession) do
      attribute_writable?(true)
      allow_nil?(false)
    end

    belongs_to :project, DevpulseServer.Teams.Project do
      attribute_writable?(true)
      allow_nil?(false)
    end
  end

  actions do
    defaults([:read])

    create :ping do
      accept([:project_name, :branch, :repo_path, :has_changes, :session_id, :project_id])
    end
  end
end
