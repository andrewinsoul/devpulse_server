defmodule DevpulseServer.Onboarding do
  use Ash.Domain

  resources do
    resource(DevpulseServer.Onboarding.DeveloperInvite)
  end
end
