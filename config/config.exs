# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :devpulse_server,
  generators: [timestamp_type: :utc_datetime],
  ash_domains: [
    DevpulseServer.Accounts,
    DevpulseServer.Activity,
    DevpulseServer.Agents,
    DevpulseServer.Identity,
    DevpulseServer.Onboarding,
    DevpulseServer.Organizations,
    DevpulseServer.Teams
  ]

config :devpulse_server,
  ecto_repos: [DevpulseServer.Core.Repo]

config :devpulse_server, DevpulseServer.Accounts,
  token_secret:
    System.get_env(
      "JWT_SIGNING_SECRET",
      "nature_open_secret"
    )

# Configure the endpoint
config :devpulse_server, DevpulseServerWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: DevpulseServerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: DevpulseServer.PubSub,
  live_view: [signing_salt: "gFgLNVPq"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
