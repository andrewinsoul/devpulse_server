defmodule DevpulseServer.Activity do
  use Ash.Domain

  require Ash.{Query, Expr}

  resources do
    resource(DevpulseServer.Activity.Heartbeat)
  end

  alias DevpulseServer.Activity.Heartbeat
  alias DevpulseServer.Agents.AgentSession
  alias DevpulseServer.Agents.SessionToken

  def ping(attrs, raw_token) when is_map(attrs) and is_binary(raw_token) do
    attrs = normalize_heartbeat_attrs(attrs)

    with {:ok, claims} <- verify_session_token(raw_token),
         {:ok, session_id} <- get_required_attr(attrs, :session_id),
         :ok <- verify_claim_session_id(claims, session_id),
         {:ok, session} <- verify_session(claims),
         {:ok, heartbeat} <- create_heartbeat(attrs, session) do
      {:ok, heartbeat}
    else
      {:error, :missing_session_token} ->
        {:error, :missing_session_token}

      {:error, :invalid_session_token} ->
        {:error, :invalid_session_token}

      {:error, :missing_session_id} ->
        {:error, :missing_session_id}

      {:error, :invalid_session} ->
        {:error, :invalid_session}

      {:error, error} ->
        {:error, error}
    end
  end

  def ping(_attrs, _raw_token), do: {:error, :invalid_session_token}

  defp verify_session_token(raw_token) do
    case SessionToken.verify(raw_token) do
      {:ok, claims} ->
        {:ok, claims}

      {:error, _reason} ->
        {:error, :invalid_session_token}
    end
  rescue
    _ -> {:error, :invalid_session_token}
  end

  defp verify_claim_session_id(claims, session_id) do
    if claims["agent_session_id"] == session_id do
      :ok
    else
      {:error, :invalid_session}
    end
  end

  defp verify_session(claims) do
    session_id = claims["agent_session_id"]
    developer_profile_id = claims["developer_profile_id"]
    team_id = claims["team_id"]

    AgentSession
    |> Ash.Query.for_read(:read, %{})
    |> Ash.Query.filter(
      Ash.Expr.expr(
        id == ^session_id and
          developer_profile_id == ^developer_profile_id and
          project.team_id == ^team_id
      )
    )
    |> Ash.read_one()
    |> case do
      {:ok, %AgentSession{} = session} ->
        case Ash.load(session, :project) do
          {:ok, loaded_session} -> {:ok, loaded_session}
          {:error, _reason} -> {:error, :invalid_session}
        end

      {:ok, nil} ->
        {:error, :invalid_session}

      {:error, _reason} ->
        {:error, :invalid_session}
    end
  end

  defp create_heartbeat(attrs, session) do
    heartbeat_attrs =
      attrs
      |> Map.put(:session_id, session.id)
      |> Map.put(:project_id, session.project_id)
      |> Map.put(:project_name, session.project.name)

    case find_existing_heartbeat(attrs.event_id, session.id) do
      {:ok, %Heartbeat{} = existing} ->
        {:ok, existing}

      :not_found ->
        case Heartbeat
             |> Ash.Changeset.for_create(:ping, heartbeat_attrs)
             |> Ash.create() do
          {:ok, heartbeat} ->
            {:ok, heartbeat}

          {:error, error} ->
            case find_existing_heartbeat(attrs.event_id, session.id) do
              {:ok, %Heartbeat{} = existing} -> {:ok, existing}
              _ -> {:error, error}
            end
        end

      {:error, _reason} = error ->
        error
    end
  end

  defp find_existing_heartbeat(event_id, session_id) do
    Heartbeat
    |> Ash.Query.for_read(:read, %{})
    |> Ash.Query.filter(Ash.Expr.expr(event_id == ^event_id and session_id == ^session_id))
    |> Ash.read_one()
    |> case do
      {:ok, nil} -> :not_found
      {:ok, heartbeat} -> {:ok, heartbeat}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_heartbeat_attrs(attrs) do
    %{
      event_id: get_attr(attrs, :event_id),
      session_id: get_attr(attrs, :session_id),
      project_name: get_attr(attrs, :project_name),
      branch: get_attr(attrs, :git_branch),
      repo_path: get_attr(attrs, :repo_path),
      has_changes: get_attr(attrs, :has_uncommitted_changes),
      captured_at: get_attr(attrs, :captured_at) || DateTime.utc_now()
    }
  end

  defp get_attr(attrs, key) do
    case Map.fetch(attrs, key) do
      {:ok, value} -> value
      :error -> Map.get(attrs, Atom.to_string(key))
    end
  end

  defp get_required_attr(attrs, key) do
    case get_attr(attrs, key) do
      nil ->
        {:error, String.to_atom("missing_#{key}")}

      value ->
        {:ok, value}
    end
  end
end
