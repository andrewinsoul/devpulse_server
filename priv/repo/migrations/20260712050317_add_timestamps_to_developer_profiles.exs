defmodule DevpulseServer.Core.Repo.Migrations.AddTimestampsToDeveloperProfiles do
  use Ecto.Migration

  def change do
    alter table(:developer_profiles) do
      timestamps(type: :utc_datetime_usec)
    end
  end
end
