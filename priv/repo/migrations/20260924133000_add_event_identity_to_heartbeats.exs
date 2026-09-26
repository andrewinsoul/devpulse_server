defmodule DevpulseServer.Core.Repo.Migrations.AddEventIdentityToHeartbeats do
  use Ecto.Migration

  def up do
    alter table(:heartbeats) do
      add(:event_id, :text)
      add(:captured_at, :utc_datetime_usec)
    end

    execute("UPDATE heartbeats SET event_id = id::text WHERE event_id IS NULL")
    execute("UPDATE heartbeats SET captured_at = inserted_at WHERE captured_at IS NULL")

    alter table(:heartbeats) do
      modify(:event_id, :text, null: false)
      modify(:captured_at, :utc_datetime_usec, null: false)
    end

    create(
      unique_index(:heartbeats, [:session_id, :event_id],
        name: "heartbeats_unique_session_event_id_index"
      )
    )
  end

  def down do
    drop_if_exists(
      unique_index(:heartbeats, [:session_id, :event_id],
        name: "heartbeats_unique_session_event_id_index"
      )
    )

    alter table(:heartbeats) do
      remove(:captured_at)
      remove(:event_id)
    end
  end
end
