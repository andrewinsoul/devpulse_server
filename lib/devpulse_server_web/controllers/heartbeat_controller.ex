defmodule DevpulseServerWeb.HeartbeatController do
  use DevpulseServerWeb, :controller

  def create(conn, params) do
    params = Map.put_new(params, "session_token", bearer_token(conn))

    case DevpulseServer.Activity.ping(params) do
      {:ok, heartbeat} ->
        conn
        |> put_status(:created)
        |> json(%{data: serialize_heartbeat(heartbeat)})

      {:error, :invalid_session_token} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{errors: [%{detail: "Invalid or expired session token."}]})

      {:error, :missing_session_token} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{errors: [%{detail: "Missing session token."}]})

      {:error, %Ash.Error.Invalid{} = error} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: [%{detail: Exception.message(error)}]})

      {:error, error} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{errors: [%{detail: Exception.message(error)}]})
    end
  end

  defp serialize_heartbeat(heartbeat) do
    %{
      id: heartbeat.id,
      agent_session_id: heartbeat.agent_session_id,
      team_id: heartbeat.team_id,
      project_name: heartbeat.project_name,
      branch: heartbeat.branch,
      repo_path: heartbeat.repo_path,
      has_changes: heartbeat.has_changes,
      inserted_at: heartbeat.inserted_at
    }
  end

  defp bearer_token(conn) do
    conn
    |> get_req_header("authorization")
    |> List.first()
    |> case do
      <<"Bearer ", token::binary>> -> token
      <<"bearer ", token::binary>> -> token
      _ -> nil
    end
  end
end
