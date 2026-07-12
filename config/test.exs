import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :devpulse_server, DevpulseServerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "VNIKGJtDSi+1enuV4wC5twwJ+/9vyjFzWgeNzkXo5BqcSVoLPAoKdaqw16AQynqE",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
