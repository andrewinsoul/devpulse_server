defmodule DevpulseServer.Activity do
  use Ash.Domain

  resources do
    resource(DevpulseServer.Activity.Heartbeat)
  end

  alias DevpulseServer.Activity.Heartbeat
  alias DevpulseServer.Agents.SessionToken

  def ping(attrs) when is_map(attrs) do
    attrs = normalize_heartbeat_attrs(attrs)

    with {:ok, session_token} <- get_required_attr(attrs, :session_token) do
      case SessionToken.verify(session_token) do
        {:ok, %{"agent_session_id" => agent_session_id, "team_id" => team_id}} ->
          heartbeat_attrs = Map.delete(attrs, :session_token)

          with {:ok, heartbeat} <-
                 Heartbeat
                 |> Ash.Changeset.for_create(
                   :ping,
                   heartbeat_attrs
                   |> Map.put(:agent_session_id, agent_session_id)
                   |> Map.put(:team_id, team_id)
                 )
                 |> Ash.create() do
            {:ok, heartbeat}
          end

        {:ok, _claims} ->
          {:error, :invalid_session_token}

        {:error, _reason} ->
          {:error, :invalid_session_token}
      end
    else
      {:error, _} -> {:error, :missing_session_token}
    end
  end

  defp normalize_heartbeat_attrs(attrs) do
    %{
      session_token: get_attr(attrs, :session_token),
      project_name: get_attr(attrs, :project_name),
      branch: get_attr(attrs, :branch),
      repo_path: get_attr(attrs, :repo_path),
      has_changes: get_attr(attrs, :has_changes)
    }
  end

  defp get_attr(attrs, key), do: Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))

  defp get_required_attr(attrs, key) do
    case get_attr(attrs, key) do
      nil -> {:error, :missing}
      value -> {:ok, value}
    end
  end
end
