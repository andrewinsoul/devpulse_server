defmodule DevpulseServer.Agents do
  use Ash.Domain

  require Ash.Query

  resources do
    resource(DevpulseServer.Agents.AgentSession)
    resource(DevpulseServer.Agents.ApiToken)
  end

  alias DevpulseServer.Agents.AgentSession
  alias DevpulseServer.Agents.SessionToken

  def resolve_session(attrs) when is_map(attrs) do
    attrs = normalize_handshake_attrs(attrs)

    with {:ok, session} <-
           AgentSession
           |> Ash.Changeset.for_create(:resolve_session, attrs)
           |> Ash.create(),
         {:ok, session_token} <- SessionToken.sign(session) do
      {:ok,
       %{
         agent_session: session,
         session_token: session_token,
         session_token_expires_in: SessionToken.max_age()
       }}
    end
  end

  defp normalize_handshake_attrs(attrs) do
    team_id = get_attr(attrs, :team_id) || resolve_team_id(get_attr(attrs, :team_slug))

    %{
      raw_token: get_attr(attrs, :api_token) || get_attr(attrs, :raw_token),
      hardware_fingerprint: get_attr(attrs, :hardware_fingerprint),
      hostname: get_attr(attrs, :hostname),
      os: get_attr(attrs, :os),
      team_id: team_id
    }
  end

  defp get_attr(attrs, key) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end

  defp resolve_team_id(nil), do: nil

  defp resolve_team_id(team_slug) when is_binary(team_slug) do
    case DevpulseServer.Teams.Team
         |> Ash.Query.for_read(:read, %{})
         |> Ash.Query.filter(slug == ^team_slug)
         |> Ash.read_one() do
      {:ok, %{id: id}} -> id
      _ -> nil
    end
  end
end
