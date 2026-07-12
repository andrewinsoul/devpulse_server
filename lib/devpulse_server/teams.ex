defmodule DevpulseServer.Teams do
  use Ash.Domain

  resources do
    resource(DevpulseServer.Teams.Team)
    resource(DevpulseServer.Teams.Project)
    resource(DevpulseServer.Teams.Membership)
  end
end
