defmodule DevpulseServerWeb.AgentSessionController do
  use DevpulseServerWeb, :controller

  def create(conn, %{"agent_session" => session_params}) do
    DevpulseServer.Agents.AgentSession
    |> Ash.Changeset.for_create(:resolve_session, session_params)
    |> Ash.create()
    |> case do
      {:ok, agent_session} ->
        conn
        |> put_status(:ok)
        |> json(%{
          status: "success",
          session_id: agent_session.id,
          project_id: agent_session.project_id,
          message: "Session resolved successfully"
        })

      {:error, error} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{status: "error", details: Ash.Error.to_error_class(error)})
    end
  end
end
