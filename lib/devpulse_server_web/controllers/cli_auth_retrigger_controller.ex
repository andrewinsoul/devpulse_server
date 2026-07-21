defmodule DevpulseServerWeb.CliAuthRetriggerController do
  use DevpulseServerWeb, :controller

  require Ash.Query
  import Ash.Expr
  alias DevpulseServer.Onboarding
  alias DevpulseServer.Onboarding.DeveloperInvite

  @doc """
  POST /api/v1/cli/auth/retrigger
  Called by the CLI when the original onboarding cache has expired.
  """
  def retrigger(conn, %{"invite_token" => invite_token}) do
    query =
      DeveloperInvite |> Ash.Query.filter(expr(token == ^invite_token and status == :accepted))

    case Ash.read_one(query, domain: Onboarding) do
      {:ok, %DeveloperInvite{} = invite} ->
        pairing_code =
          :crypto.strong_rand_bytes(16)
          |> Base.encode16(case: :lower)

        DevpulseServer.TokenCache.put(pairing_code, invite.token, ttl: :timer.minutes(5))

        verification_url =
          DevpulseServerWeb.Endpoint.url() <> "/auth/cli/verify?code=#{pairing_code}"

        conn
        |> put_status(200)
        |> json(%{
          "status" => "success",
          "verification_url" => verification_url,
          "pairing_code" => pairing_code
        })

      {:ok, nil} ->
        conn
        |> put_status(404)
        |> json(%{"error" => "Invalid or uncompleted invite tracking token."})
    end
  end
end
