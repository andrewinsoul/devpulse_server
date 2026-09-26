defmodule DevpulseServer.Agents do
  use Ash.Domain

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
         {:ok, loaded_session} <- Ash.load(session, :project),
         {:ok, session_token} <- SessionToken.sign(loaded_session) do
      {:ok,
       %{
         agent_session: loaded_session,
         session_token: session_token,
         session_token_expires_in: SessionToken.max_age()
       }}
    end
  end

  defp normalize_handshake_attrs(attrs) do
    %{
      raw_token: get_attr(attrs, :api_token) || get_attr(attrs, :raw_token),
      project_id: get_attr(attrs, :project_id),
      hardware_fingerprint: get_attr(attrs, :hardware_fingerprint),
      hostname: get_attr(attrs, :hostname),
      os: get_attr(attrs, :os)
    }
  end

  defp get_attr(attrs, key) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end
end