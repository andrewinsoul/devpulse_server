defmodule DevpulseServerWeb.CliTeamController do
  use DevpulseServerWeb, :controller

  require Ash.Query
  alias DevpulseServer.Teams.Team

  @doc """
  GET /api/v1/cli/teams
  Returns only the teams that the authenticated developer belongs to.
  """
  def index(conn, _params) do
    domain = DevpulseServer.Teams

    current_profile = conn.assigns.current_profile

    query =
      Team
      |> Ash.Query.filter(developer_profiles.id == ^current_profile.id)
      |> Ash.Query.sort(name: :asc)

    case Ash.read(query, domain: domain) do
      {:ok, teams} ->
        teams_json =
          Enum.map(teams, fn team ->
            %{
              "id" => team.id,
              "name" => team.name,
              "slug" => team.slug
            }
          end)

        conn
        |> put_status(200)
        |> json(%{"status" => "success", "teams" => teams_json})

      {:error, error} ->
        conn
        |> put_status(500)
        |> json(%{"error" => "Failed to retrieve your teams.", "details" => inspect(error)})
    end
  end
end
