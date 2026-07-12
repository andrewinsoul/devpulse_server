defmodule DevpulseServer.Core.Repo do
  use AshPostgres.Repo,
    otp_app: :devpulse_server

  def installed_extensions() do
    ["ash-functions"]
  end

  def min_pg_version do
    %Version{major: 16, minor: 0, patch: 0}
  end
end
