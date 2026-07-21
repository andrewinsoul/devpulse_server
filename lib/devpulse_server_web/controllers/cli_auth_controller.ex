defmodule DevpulseServerWeb.CliAuthController do
  use DevpulseServerWeb, :controller

  require Ash.Query
  import Ash.Expr
  alias DevpulseServer.Agents.ApiToken
  alias DevpulseServer.TokenCache
  alias DevpulseServer.Onboarding
  alias DevpulseServer.Onboarding.DeveloperInvite

  def exchange(conn, %{"invite_token" => invite_token, "name" => name} = params) do
    if invite_token && name do
      query =
        DeveloperInvite
        |> Ash.Query.for_read(:by_token, %{token: invite_token})

      case Ash.read_one(query, domain: Onboarding) do
        {:ok, %DeveloperInvite{} = invite} ->
          changeset =
            invite
            |> Ash.Changeset.for_update(:accept_invite, %{
              name: name,
              avatar_url: Map.get(params, "avatar_url")
            })

          case Ash.update(changeset, domain: Onboarding) do
            {:ok, updated_invite} ->
              render(conn, :accept_invite_success,
                message: "Terminal authorized successfully!",
                token: updated_invite.token
              )

            {:error, _} ->
              render(conn, :accept_invite_form,
                invite: invite,
                token: invite_token,
                error_message: "Failed to create profile. Please try again."
              )
          end

        {:ok, nil} ->
          render(conn, :error, message: "Invite token invalid or already claimed.")
      end
    else
      render(conn, :error, message: "Missing required profile parameters.")
    end
  end

  def exchange(conn, %{"invite_token" => invite_token}) do
    query =
      DeveloperInvite
      |> Ash.Query.filter(expr(token == ^invite_token and status == :accepted))

    case Ash.read_one(query, domain: Onboarding) do
      {:ok, %DeveloperInvite{} = invite} ->
        case Ash.Resource.get_metadata(invite, :raw_token) do
          nil ->
            conn
            |> put_status(401)
            |> json(%{"error" => "Token metadata cleared or unavailable."})

          pat_string ->
            conn
            |> put_status(200)
            |> json(%{
              "status" => "success",
              "token" => pat_string
            })
        end

      {:ok, nil} ->
        conn
        |> put_status(404)
        |> json(%{"error" => "Invite token not ready or unrecognized."})

      {:error, error} ->
        conn
        |> put_status(500)
        |> json(%{"error" => "Database read exception: #{inspect(error)}"})
    end
  end

  def exchange(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{"error" => "Missing required payload attributes: invite_token and name"})
  end

  def authorize(conn, %{"code" => pairing_code}) do
    case DevpulseServer.TokenCache.get(pairing_code) do
      nil ->
        render(conn, "error.html",
          message: "This authorization link has expired. Please try again from the CLI."
        )

      invite_token ->
        query = DeveloperInvite |> Ash.Query.filter(token == ^invite_token)

        case Ash.read_one(query, domain: DevpulseServer.Onboarding) do
          {:ok, %DeveloperInvite{} = invite} ->
            invite = Ash.load!(invite, :developer_profile, domain: DevpulseServer.Onboarding)

            case invite.developer_profile do
              %DevpulseServer.Identity.DeveloperProfile{id: profile_id, name: name} ->
                api_token_changeset =
                  ApiToken
                  |> Ash.Changeset.new()
                  |> Ash.Changeset.set_argument(:developer_profile_id, profile_id)
                  |> Ash.Changeset.for_create(:generate_for_developer, %{
                    name: "#{String.downcase(name)}_reauth"
                  })

                case Ash.create(api_token_changeset, domain: DevpulseServer.Agents) do
                  {:ok, api_token_record} ->
                    raw_pat = Ash.Resource.get_metadata(api_token_record, :raw_token)

                    DevpulseServer.TokenCache.put(
                      pairing_code,
                      %{
                        status: :approved,
                        token: raw_pat,
                        developer_profile_id: profile_id
                      },
                      ttl: :timer.minutes(15)
                    )

                    render(conn, "success.html",
                      message: "Terminal authorized successfully! You can close this tab."
                    )

                  {:error, _changeset_error} ->
                    render(conn, "error.html", message: "Failed to generate terminal token.")
                end

              nil ->
                render(conn, "error.html",
                  message: "No developer profile associated with this invite."
                )
            end

          {:ok, nil} ->
            render(conn, "error.html", message: "Associated invite could not be found.")
        end
    end
  end

  def show(conn, %{"code" => pairing_code}) do
    case DevpulseServer.TokenCache.get(pairing_code) do
      nil ->
        conn
        |> put_status(:bad_request)
        |> render(:error,
          message:
            "This authorization link has expired or is invalid. Please try again from your terminal."
        )

      _invite_token ->
        render(conn, :show, pairing_code: pairing_code)
    end
  end

  def show(conn, %{"token" => token} = params) do
    pairing_code = params["code"]

    query =
      DeveloperInvite
      |> Ash.Query.for_read(:by_token, %{token: token})

    case Ash.read_one(query, domain: DevpulseServer.Onboarding) do
      {:ok, %DeveloperInvite{} = invite} ->
        render(conn, :accept_invite_form,
          invite: invite,
          token: token,
          pairing_code: pairing_code,
          error_message: nil
        )

      {:ok, nil} ->
        render(conn, :error, message: "This invite token is invalid or has expired.")
    end
  end

  def show(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> render(:error, message: "Missing pairing code parameter.")
  end

  def check_status(conn, %{"pairing_code" => pairing_code}) do
    case TokenCache.get_pairing_status(pairing_code) do
      {:ok, %{status: :approved, token: pat} = payload} ->
        TokenCache.delete_pairing_code(pairing_code)

        conn
        |> put_status(:ok)
        |> json(%{
          status: "approved",
          token: pat,
          user: Map.get(payload, :user)
        })

      {:ok, %{status: :pending}} ->
        conn
        |> put_status(:ok)
        |> json(%{status: "pending"})

      {:ok, invite_token} when is_binary(invite_token) ->
        conn
        |> put_status(:ok)
        |> json(%{status: "pending"})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Pairing session expired or not found."})

      _ ->
        conn
        |> put_status(:ok)
        |> json(%{status: "pending"})
    end
  end
end
