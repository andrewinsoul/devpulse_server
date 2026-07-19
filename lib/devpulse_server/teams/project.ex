defmodule DevpulseServer.Teams.Project do
  # TODO (v2): Rename Workspace -> Project.
  #
  # The CLI currently uses "Workspace", but in the domain model a Workspace
  # represents a software project/repository. These are the same concept.
  # Rename once the core backend architecture stabilizes.
  use Ash.Resource,
    domain: DevpulseServer.Teams,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("projects")
    repo(DevpulseServer.Core.Repo)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:name, :string, allow_nil?: false)
    attribute(:git_remote_url, :string, allow_nil?: false)
  end

  relationships do
    belongs_to :team, DevpulseServer.Teams.Team do
      allow_nil?(false)
      attribute_public?(true)
    end

    has_many(:agent_sessions, DevpulseServer.Agents.AgentSession)
  end

  identities do
    identity(:unique_git_remote, [:git_remote_url])
    identity(:unique_team_project_name, [:team_id, :name])
  end

  actions do
    defaults([:destroy])

    read :by_git_remote do
      argument(:git_remote_url, :string, allow_nil?: false)

      filter(expr(git_remote_url == ^arg(:git_remote_url)))

      get?(true)
    end

    create :create_project do
      accept([:name, :git_remote_url])
      argument(:team_id, :uuid, allow_nil?: false)

      change(manage_relationship(:team_id, :team, type: :append_and_remove))
    end
  end
end
