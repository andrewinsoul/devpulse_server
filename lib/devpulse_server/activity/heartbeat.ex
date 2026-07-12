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
    belongs_to(:agent_session, DevpulseServer.Agents.AgentSession)
    # belongs_to(:team, DevpulseServer.Teams.Team) do
    #   attribute_public?(true)
    # end
  end

  actions do
    defaults([:read])

    create :ping do
      accept([:project_name, :branch, :repo_path, :has_changes])
      argument(:agent_session_id, :uuid, allow_nil?: false)
      argument(:team_id, :uuid, allow_nil?: false)
      change(set_attribute(:agent_session_id, arg(:agent_session_id)))
      change(set_attribute(:team_id, arg(:team_id)))
    end
  end
end
