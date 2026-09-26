defmodule DevpulseServerWeb.AgentSessionController do
  use DevpulseServerWeb, :controller

  def handshake(conn, session_params) do
    with {:ok, raw_token} <- bearer_token(conn),
         {:ok, resolved} <-
           DevpulseServer.Agents.resolve_session(Map.put(session_params, "raw_token", raw_token)),
         {:ok, session} <- Ash.load(resolved.agent_session, :project) do
      conn
      |> put_status(:ok)
      |> json(%{
        status: "success",
        session: %{
          session_id: session.id,
          project_id: session.project_id,
          project_name: session.project.name,
          git_remote_url: session.project.git_remote_url,
          session_token: resolved.session_token,
          expires_in: resolved.session_token_expires_in
        }
      })
    else
      {:error, :missing_authorization} ->
        unauthorized(conn, "Missing or invalid Authorization header.")

      {:error, %Ash.Error.Invalid{errors: errors}} ->
        unauthorized(conn, error_messages(errors))

      # {:error, %Ash.Error.Invalid{} = error} ->
      #   unauthorized(conn, error_messages(error))

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          status: "error",
          details: error_detail(reason)
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

  defp unauthorized(conn, details) do
    conn
    |> put_status(:unauthorized)
    |> json(%{
      status: "error",
      details: details
    })
  end

  defp error_messages(errors) when is_list(errors),
    do: Enum.map_join(errors, ", ", &error_detail/1)

  defp error_messages(error), do: error_detail(error)

  defp error_detail(error) when is_binary(error), do: error
  defp error_detail(error) when is_atom(error), do: Atom.to_string(error)

  defp error_detail(error) do
    if Kernel.is_exception(error), do: Exception.message(error), else: inspect(error)
  end
end
