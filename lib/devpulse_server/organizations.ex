defmodule DevpulseServer.Organizations do
  use Ash.Domain

  resources do
    resource(DevpulseServer.Organizations.Organization)
  end
end
