defmodule DevpulseServer.Agents.AgentSession do
  use Ash.Resource,
    domain: DevpulseServer.Agents,
    data_layer: AshPostgres.DataLayer

  require Ash.{Query, Expr}

  postgres do
    table("agent_sessions")
    repo(DevpulseServer.Core.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:hardware_fingerprint, :string,
      allow_nil?: false,
      public?: true,
      source: :computer_identifier
    )

    attribute(:hostname, :string, public?: true)
    attribute(:os, :string, public?: true)
    attribute(:last_seen_at, :utc_datetime, allow_nil?: false)
  end

  relationships do
    belongs_to :developer_profile, DevpulseServer.Identity.DeveloperProfile do
      allow_nil?(false)
      attribute_public?(true)
    end

    belongs_to :project, DevpulseServer.Teams.Project do
      allow_nil?(false)
      attribute_public?(true)
    end

    has_many(:heart_beats, DevpulseServer.Activity.Heartbeat)

    belongs_to :api_token, DevpulseServer.Agents.ApiToken do
      allow_nil?(false)
    end
  end

  identities do
    identity(:unique_computer_session, [:developer_profile_id, :project_id, :hardware_fingerprint])
  end

  defp verify_token(changeset) do
    raw_token = Ash.Changeset.get_argument(changeset, :raw_token)

    DevpulseServer.Agents.ApiToken
    |> Ash.Query.for_read(:verify_token, %{token: raw_token})
    |> Ash.Query.filter(is_nil(revoked_at))
    |> Ash.Query.load(:developer_profile)
    |> Ash.read_one()
    |> case do
      {:ok, %{developer_profile: profile} = api_token} when not is_nil(profile) ->
        {:ok, api_token}

      {:ok, _} ->
        {:error, "Unauthorized: API token is not associated with a developer."}

      {:error, _} ->
        {:error, "Unauthorized: Invalid or revoked API agent token."}
    end
  end

  defp load_project(changeset) do
    git_remote_url = Ash.Changeset.get_argument(changeset, :git_remote_url)

    DevpulseServer.Teams.Project
    |> Ash.Query.for_read(:by_git_remote, %{
      git_remote_url: git_remote_url
    })
    |> Ash.Query.load(:team)
    |> Ash.read_one()
    |> case do
      {:ok, nil} ->
        {:error, "This repository is not registered with DevPulse."}

      {:ok, project} ->
        {:ok, project}

      {:error, _reason} ->
        {:error, "Unable to resolve project."}
    end
  end

  defp populate_session(changeset, api_token, project) do
    hardware_fingerprint =
      Ash.Changeset.get_argument(changeset, :hardware_fingerprint)

    hostname =
      Ash.Changeset.get_attribute(changeset, :hostname)

    os =
      Ash.Changeset.get_attribute(changeset, :os)

    changeset
    |> Ash.Changeset.change_attribute(:hardware_fingerprint, hardware_fingerprint)
    |> Ash.Changeset.change_attribute(:last_seen_at, DateTime.utc_now())
    |> Ash.Changeset.change_attribute(
      :developer_profile_id,
      api_token.developer_profile.id
    )
    |> Ash.Changeset.change_attribute(:project_id, project.id)
    |> Ash.Changeset.change_attribute(:api_token_id, api_token.id)
    |> Ash.Changeset.change_attribute(:hostname, hostname)
    |> Ash.Changeset.change_attribute(:os, os)
  end

  defp verify_membership(api_token, project) do
    profile = api_token.developer_profile

    DevpulseServer.Teams.Membership
    |> Ash.Query.for_read(:read, %{})
    |> Ash.Query.filter(
      Ash.Expr.expr(
        team_id == ^project.team_id and
          developer_profile_id == ^profile.id
      )
    )
    |> Ash.read_one()
    |> case do
      {:ok, %DevpulseServer.Teams.Membership{}} ->
        :ok

      {:ok, nil} ->
        {:error, "Unauthorized: Developer is not a member of #{project.team.name}."}

      {:error, _reason} ->
        {:error, "Unable to verify developer membership."}
    end
  end

  actions do
    defaults([:read, :update, :destroy])

    create :resolve_session do
      argument(:raw_token, :string, allow_nil?: false)
      argument(:hardware_fingerprint, :string, allow_nil?: false)
      argument(:git_remote_url, :string, allow_nil?: false)

      accept([:hostname, :os])

      upsert?(true)
      upsert_identity(:unique_computer_session)
      upsert_fields([:last_seen_at, :hostname, :os, :api_token_id])

      change(fn changeset, _context ->
        with {:ok, api_token} <- verify_token(changeset),
             {:ok, project} <- load_project(changeset),
             :ok <- verify_membership(api_token, project) do
          populate_session(changeset, api_token, project)
        else
          {:error, reason} ->
            Ash.Changeset.add_error(changeset, reason)
        end
      end)
    end
  end
end
