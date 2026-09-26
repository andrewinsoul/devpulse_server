defmodule DevpulseServer.Onboarding.DeveloperInvite do
  alias DevpulseServer.Identity.DeveloperProfile
  alias DevpulseServer.Teams.Project

  use Ash.Resource,
    domain: DevpulseServer.Onboarding,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("developer_invites")
    repo(DevpulseServer.Core.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :email, :string do
      allow_nil?(false)
    end

    attribute :token, :string do
      allow_nil?(false)
    end

    attribute :status, :atom do
      constraints(one_of: [:pending, :accepted, :expired])
      default(:pending)
    end

    attribute(:expires_at, :utc_datetime)
  end

  relationships do
    belongs_to(:team, DevpulseServer.Teams.Team)

    belongs_to(:project, Project) do
      allow_nil?(true)
    end

    has_one :developer_profile, DevpulseServer.Identity.DeveloperProfile do
      destination_attribute(:invite_id)
      from_many?(true)
    end
  end

  identities do
    identity(:unique_token, [:token])
  end

  actions do
    defaults([:read, :destroy])

    create :invite_developer do
      accept([:email])
      argument(:team_id, :uuid, allow_nil?: false)
      argument(:project_id, :uuid, allow_nil?: false)

      change(fn changeset, _context ->
        team_id = Ash.Changeset.get_argument(changeset, :team_id)
        project_id = Ash.Changeset.get_argument(changeset, :project_id)

        case Ash.get(Project, project_id) do
          {:ok, %{team_id: ^team_id}} ->
            changeset

          {:ok, _project} ->
            Ash.Changeset.add_error(
              changeset,
              field: :project_id,
              message: "Project does not belong to the selected team."
            )

          {:ok, nil} ->
            Ash.Changeset.add_error(
              changeset,
              field: :project_id,
              message: "Project could not be found."
            )

          {:error, reason} ->
            Ash.Changeset.add_error(
              changeset,
              field: :project_id,
              message: "Project could not be resolved: #{inspect(reason)}"
            )
        end
      end)

      change(manage_relationship(:team_id, :team, type: :append))
      change(manage_relationship(:project_id, :project, type: :append))

      change(fn changeset, _context ->
        invite_token = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
        seven_days_from_now = DateTime.utc_now() |> DateTime.add(7, :day)

        changeset
        |> Ash.Changeset.change_attribute(:token, "dp_invite_#{invite_token}")
        |> Ash.Changeset.change_attribute(:expires_at, seven_days_from_now)
        |> Ash.Changeset.change_attribute(:status, :pending)
      end)
    end

    read :by_token do
      argument(:token, :string, allow_nil?: false)
      filter(expr(token == ^arg(:token) and status == :pending and expires_at > now()))
      get?(true)
    end

    update :accept_invite do
      require_atomic?(false)
      argument(:name, :string, allow_nil?: false)
      argument(:avatar_url, :string)

      change(set_attribute(:status, :accepted))

      change(fn changeset, _context ->
        Ash.Changeset.after_action(changeset, fn changeset, invite ->
          name = Ash.Changeset.get_argument(changeset, :name)
          avatar_url = Ash.Changeset.get_argument(changeset, :avatar_url)

          profile_params = %{
            name: name,
            avatar_url: avatar_url,
            email: invite.email,
            invite_id: invite.id,
            team_id: invite.team_id
          }

          DeveloperProfile
          |> Ash.Changeset.for_create(:create_from_invite, profile_params)
          |> Ash.create()
        end)
      end)
    end
  end
end