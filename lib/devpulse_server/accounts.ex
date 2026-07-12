defmodule DevpulseServer.Accounts do
  use Ash.Domain

  resources do
    resource(DevpulseServer.Accounts.User)
    resource(DevpulseServer.Accounts.Token)
  end
end
