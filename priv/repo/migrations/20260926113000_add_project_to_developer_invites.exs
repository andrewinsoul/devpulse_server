defmodule DevpulseServer.Repo.Migrations.AddProjectToDeveloperInvites do
  use Ecto.Migration

  def up do
    alter table(:developer_invites) do
      add(
        :project_id,
        references(:projects,
          column: :id,
          name: "developer_invites_project_id_fkey",
          type: :uuid,
          prefix: "public"
        ),
        null: true
      )
    end

    create(index(:developer_invites, [:project_id], name: "developer_invites_project_id_index"))
  end

  def down do
    drop_if_exists(
      index(:developer_invites, [:project_id], name: "developer_invites_project_id_index")
    )

    drop(constraint(:developer_invites, "developer_invites_project_id_fkey"))

    alter table(:developer_invites) do
      remove(:project_id)
    end
  end
end