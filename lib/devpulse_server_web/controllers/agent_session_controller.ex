defmodule DevpulseServerWeb.AgentSessionController do
  use DevpulseServerWeb, :controller

  def handshake(conn, session_params) do
    with {:ok, raw_token} <- bearer_token(conn),
         {:ok, session} <- resolve_session(raw_token, session_params) do
      conn
      |> put_status(:ok)
      |> json(%{
        session: %{
          session_id: session.id,
          project_id: session.project_id,
          project_name: session.project.name,
          git_remote_url: session.project.git_remote_url
        }
      })
    else
      {:error, :missing_authorization} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          status: "error",
          details: "Missing or invalid Authorization header."
        })

      {:error, %Ash.Error.Invalid{errors: errors}} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          status: "error",
          details: error_messages(errors)
        })

      {:error, %Ash.Error.Invalid{} = error} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          status: "error",
          details: error_messages(error)
        })

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          status: "error",
          details: Exception.message(reason)
        })
    end
  end

  defp bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] when token != "" ->
        {:ok, token}

      _ ->
        {:error, :missing_authorization}
    end
  end

  defp resolve_session(raw_token, params) do
    %{
      "project_id" => project_id,
      "hardware_fingerprint" => hardware_fingerprint,
      "hostname" => hostname,
      "operating_system" => os
    } = params

    DevpulseServer.Agents.AgentSession
    |> Ash.Changeset.for_create(:resolve_session, %{
      raw_token: raw_token,
      project_id: project_id,
      hardware_fingerprint: hardware_fingerprint,
      hostname: hostname,
      os: os
    })
    |> Ash.create()
    |> case do
      {:ok, session} -> Ash.load(session, :project)
      error -> error
    end
  end

  defp error_messages(errors) do
    Enum.map_join(errors, ", ", &Exception.message/1)
  end
end
