defmodule DevpulseServer.Accounts.Token do
  use Ash.Resource,
    domain: DevpulseServer.Accounts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource]

  postgres do
    table("user_tokens")
    repo(DevpulseServer.Core.Repo)
  end
end
