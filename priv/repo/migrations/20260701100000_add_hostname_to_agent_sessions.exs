defmodule DevpulseServer.Core.Repo.Migrations.AddHostnameToAgentSessions do
  @moduledoc """
  Adds the hostname captured during the handshake phase.
  """

  use Ecto.Migration

  def up do
    alter table(:agent_sessions) do
      add(:hostname, :text)
    end
  end

  def down do
    alter table(:agent_sessions) do
      remove(:hostname)
    end
  end
end
