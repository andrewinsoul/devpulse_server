defmodule DevpulseServer.Identity do
  use Ash.Domain

  resources do
    resource(DevpulseServer.Identity.DeveloperProfile)
  end
end
