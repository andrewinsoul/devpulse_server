defmodule DevpulseServerWeb.CliProjectController do
  use DevpulseServerWeb, :controller

  require Ash.Query
  alias DevpulseServer.Teams.Project

  @doc """
  GET /api/v1/cli/teams/:team_id/projects
  Returns all active projects belonging to a specific team container context.
  """
  def index(conn, %{"team_id" => team_id}) do
    domain = DevpulseServer.Teams

    query =
      Project
      |> Ash.Query.filter(team_id == ^team_id)
      |> Ash.Query.sort(name: :asc)

    case Ash.read(query, domain: domain) do
      {:ok, projects} ->
        projects_json =
          Enum.map(projects, fn project ->
            %{
              "id" => project.id,
              "name" => project.name,
              "slug" => project.slug
            }
          end)

        conn
        |> put_status(200)
        |> json(%{"status" => "success", "projects" => projects_json})

      {:error, error} ->
        conn
        |> put_status(500)
        |> json(%{"error" => "Failed to fetch team projects.", "details" => inspect(error)})
    end
  end
end
