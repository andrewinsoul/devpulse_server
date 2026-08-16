defmodule DevpulseServer.Core.Repo.Migrations.RemoveAgentSessionUniqueness do
  use Ecto.Migration

  def up do
    drop_if_exists(
      unique_index(
        :agent_sessions,
        [:developer_profile_id, :project_id, :computer_identifier],
        name: "agent_sessions_unique_computer_session_index"
      )
    )
  end

  def down do
    create(
      unique_index(
        :agent_sessions,
        [:developer_profile_id, :project_id, :computer_identifier],
        name: "agent_sessions_unique_computer_session_index"
      )
    )
  end
end
