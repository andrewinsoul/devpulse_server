defmodule DevpulseServer.Core.Repo.Migrations.AddTeamMembershipsAndScopeAgentSessions do
  use Ecto.Migration

  def up do
    create table(:team_memberships, primary_key: false) do
      add(:id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true)

      add(
        :team_id,
        references(:teams,
          column: :id,
          name: "team_memberships_team_id_fkey",
          type: :uuid,
          prefix: "public"
        ),
        null: false
      )

      add(
        :developer_profile_id,
        references(:developer_profiles,
          column: :id,
          name: "team_memberships_developer_profile_id_fkey",
          type: :uuid,
          prefix: "public"
        ),
        null: false
      )
    end

    create(
      unique_index(:team_memberships, [:team_id, :developer_profile_id],
        name: "team_memberships_unique_team_membership_index"
      )
    )

    execute("""
    insert into team_memberships (team_id, developer_profile_id)
    select distinct team_id, id
    from developer_profiles
    where team_id is not null
    on conflict do nothing
    """)

    alter table(:agent_sessions) do
      add(
        :team_id,
        references(:teams,
          column: :id,
          name: "agent_sessions_team_id_fkey",
          type: :uuid,
          prefix: "public"
        )
      )
    end

    execute("""
    update agent_sessions as s
    set team_id = p.team_id
    from developer_profiles as p
    where s.developer_profile_id = p.id and s.team_id is null
    """)

    alter table(:heartbeats) do
      add(
        :team_id,
        references(:teams,
          column: :id,
          name: "heartbeats_team_id_fkey",
          type: :uuid,
          prefix: "public"
        )
      )
    end

    execute("""
    update heartbeats as h
    set team_id = s.team_id
    from agent_sessions as s
    where h.agent_session_id = s.id and h.team_id is null
    """)
  end

  def down do
    drop(constraint(:heartbeats, "heartbeats_team_id_fkey"))

    alter table(:heartbeats) do
      remove(:team_id)
    end

    drop(constraint(:agent_sessions, "agent_sessions_team_id_fkey"))

    alter table(:agent_sessions) do
      remove(:team_id)
    end

    drop(constraint(:team_memberships, "team_memberships_developer_profile_id_fkey"))
    drop(constraint(:team_memberships, "team_memberships_team_id_fkey"))
    drop(table(:team_memberships))
  end
end
