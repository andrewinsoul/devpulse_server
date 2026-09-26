defmodule DevpulseServerWeb.HeartbeatController do
  use DevpulseServerWeb, :controller

  def create(conn, params) do
    with {:ok, raw_token} <- bearer_token(conn),
         result <- DevpulseServer.Activity.ping(params, raw_token) do
      handle_result(conn, result)
    else
      {:error, :missing_session_token} ->
        handle_result(conn, {:error, :missing_session_token})
    end
  end

  defp handle_result(conn, {:ok, _heartbeat}) do
    conn
    |> put_status(:no_content)
    |> send_resp(:no_content, "")
  end

  defp handle_result(conn, {:error, :missing_session_token}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{
      errors: [%{detail: "Missing session token."}]
    })
  end

  defp handle_result(conn, {:error, :invalid_session_token}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{
      errors: [%{detail: "Invalid or expired session token."}]
    })
  end

  defp handle_result(conn, {:error, :missing_session_id}) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      errors: [%{detail: "Missing session_id."}]
    })
  end

  defp handle_result(conn, {:error, :invalid_session}) do
    conn
    |> put_status(:forbidden)
    |> json(%{
      errors: [%{detail: "Invalid or unauthorized agent session."}]
    })
  end

  defp handle_result(conn, {:error, %Ash.Error.Invalid{} = error}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{
      errors: [%{detail: Exception.message(error)}]
    })
  end

  defp handle_result(conn, {:error, error}) do
    conn
    |> put_status(:internal_server_error)
    |> json(%{
      errors: [%{detail: error_detail(error)}]
    })
  end

  defp bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] when token != "" ->
        {:ok, token}

      _ ->
        {:error, :missing_session_token}
    end
  end

  defp error_detail(error) when is_binary(error), do: error
  defp error_detail(error) when is_atom(error), do: Atom.to_string(error)

  defp error_detail(error) do
    if Kernel.is_exception(error), do: Exception.message(error), else: inspect(error)
  end
end
