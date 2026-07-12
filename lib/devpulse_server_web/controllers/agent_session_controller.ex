defmodule DevpulseServerWeb.AgentSessionController do
  use DevpulseServerWeb, :controller

  def create(conn, params) do
    params = Map.put_new(params, "api_token", bearer_token(conn))

    case DevpulseServer.Agents.resolve_session(params) do
      {:ok,
       %{
         agent_session: session,
         session_token: session_token,
         session_token_expires_in: expires_in
       }} ->
        conn
        |> put_status(:created)
        |> json(%{
          data: serialize_session(session),
          meta: %{
            session_token: session_token,
            session_token_expires_in: expires_in
          }
        })

      {:error, %Ash.Error.Invalid{} = error} ->
        render_error(conn, error)

      {:error, error} ->
        render_error(conn, error)
    end
  end

  defp serialize_session(session) do
    %{
      id: session.id,
      developer_profile_id: session.developer_profile_id,
      team_id: session.team_id,
      hardware_fingerprint: session.hardware_fingerprint,
      hostname: session.hostname,
      os: session.os,
      last_seen_at: session.last_seen_at
    }
  end

  defp render_error(conn, %Ash.Error.Invalid{} = error) do
    message = Exception.message(error)

    status =
      if String.contains?(message, "Unauthorized"), do: :unauthorized, else: :unprocessable_entity

    conn
    |> put_status(status)
    |> json(%{errors: [%{detail: message}]})
  end

  defp render_error(conn, error) do
    conn
    |> put_status(:internal_server_error)
    |> json(%{errors: [%{detail: Exception.message(error)}]})
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
