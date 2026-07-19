defmodule Mix.Tasks.Dev.Db.Rebuild do
  @shortdoc "Drops, recreates and migrates the development database"

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    ensure_dev!()

    Mix.Task.run("ecto.drop", ["--force"])
    Mix.Task.run("ecto.create")
    Mix.Task.run("ecto.migrate")

    Mix.shell().info("""

    ✅ Dev database rebuilt successfully.

    """)
  end

  defp ensure_dev! do
    if Mix.env() != :dev do
      Mix.raise("""

      dev.db.rebuild can only be executed in the :dev environment.

      Current environment:

          #{Mix.env()}

      """)
    end
  end
end
