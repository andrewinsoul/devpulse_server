defmodule DevpulseServer.Accounts.User do
  use Ash.Resource,
    domain: DevpulseServer.Accounts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication]

  postgres do
    table("users")
    repo(DevpulseServer.Core.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :email, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :hashed_password, :string do
      allow_nil?(false)
      sensitive?(true)
    end

    attribute(:name, :string) do
      public?(true)
    end
  end

  relationships do
    has_many(:organizations, DevpulseServer.Organizations.Organization)
  end

  authentication do
    tokens do
      enabled?(true)
      require_token_presence_for_authentication?(true)
      token_resource(DevpulseServer.Accounts.Token)
      store_all_tokens?(true)

      signing_secret(fn _resource, _intent ->
        {:ok,
         Application.get_env(:devpulse_server, DevpulseServer.Accounts.User)[:jwt_signing_secret]}
      end)
    end

    strategies do
      password :password do
        identity_field(:email)
        hashed_password_field(:hashed_password)
        register_action_accept([:name])
        confirmation_required?(false)
        sign_in_tokens_enabled?(true)
      end
    end
  end

  identities do
    identity(:unique_email, [:email])
  end

  actions do
    default_accept(:*)
    defaults([:read, :destroy])

    update :update do
      accept([:name, :email])
    end
  end
end
