defmodule DevpulseServer.Activity do
  use Ash.Domain

  require Ash.{Query, Expr}

  resources do
    resource(DevpulseServer.Activity.Heartbeat)
  end

  alias DevpulseServer.Activity.Heartbeat
  alias DevpulseServer.Agents.ApiToken
  alias DevpulseServer.Agents.AgentSession

  def ping(attrs, raw_token) when is_map(attrs) and is_binary(raw_token) do
    attrs = normalize_heartbeat_attrs(attrs)

    with {:ok, session_id} <- get_required_attr(attrs, :session_id),
         {:ok, api_token} <- verify_token(raw_token),
         {:ok, session} <- verify_session(session_id, api_token),
         {:ok, heartbeat} <- create_heartbeat(attrs, session) do
      {:ok, heartbeat}
    else
      {:error, :missing_session_id} ->
        {:error, :missing_session_id}

      {:error, :invalid_api_token} ->
        {:error, :invalid_api_token}

      {:error, :invalid_session} ->
        {:error, :invalid_session}

      {:error, error} ->
        {:error, error}
    end
  end

  defp verify_token(raw_token) do
    ApiToken
    |> Ash.Query.for_read(:verify_token, %{token: raw_token})
    |> Ash.Query.load(:developer_profile)
    |> Ash.read_one()
    |> case do
      {:ok, %{developer_profile: profile} = api_token}
      when not is_nil(profile) ->
        {:ok, api_token}

      {:ok, _} ->
        {:error, :invalid_api_token}

      {:error, _reason} ->
        {:error, :invalid_api_token}
    end
  end

  defp verify_session(session_id, api_token) do
    developer_profile_id = api_token.developer_profile.id

    AgentSession
    |> Ash.Query.for_read(:read, %{})
    |> Ash.Query.filter(
      Ash.Expr.expr(
        id == ^session_id and
          developer_profile_id == ^developer_profile_id
      )
    )
    |> Ash.read_one()
    |> case do
      {:ok, %AgentSession{} = session} ->
        {:ok, session}

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

    Heartbeat
    |> Ash.Changeset.for_create(:ping, heartbeat_attrs)
    |> Ash.create()
  end

  defp normalize_heartbeat_attrs(attrs) do
    %{
      session_id: get_attr(attrs, :session_id),
      project_name: get_attr(attrs, :project_name),
      branch: get_attr(attrs, :git_branch),
      repo_path: get_attr(attrs, :repo_path),
      has_changes: get_attr(attrs, :has_uncommitted_changes)
    }
  end

  defp get_attr(attrs, key) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end

  defp get_required_attr(attrs, key) do
    case get_attr(attrs, key) do
      nil ->
        {:error, :"missing_#{key}"}

      value ->
        {:ok, value}
    end
  end
end
