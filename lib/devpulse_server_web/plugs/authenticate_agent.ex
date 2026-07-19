defmodule DevpulseServerWeb.Plugs.AuthenticateAgent do
  import Plug.Conn
  import Ash.Query

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> raw_token] <- get_req_header(conn, "authorization"),
         token_hash = :crypto.hash(:sha256, raw_token) |> Base.encode16(case: :lower),
         {:ok, developer} <- find_developer(token_hash) do
      conn
      |> assign(:current_actor, developer)
    else
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Invalid or missing API Token"}))
        |> halt()
    end
  end

  defp find_developer(token_hash) do
    DevpulseServer.Agents.ApiToken
    |> filter(token_hash == ^token_hash and is_nil(revoked_at))
    |> load(:developer_profile)
    |> Ash.read_one()
    |> case do
      {:ok, %{developer_profile: profile}} when not is_nil(profile) -> {:ok, profile}
      {:ok, _no_profile} -> {:error, :profile_not_found}
      {:error, error} -> {:error, error}
    end
  end
end
