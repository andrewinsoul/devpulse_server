defmodule DevpulseServerWeb.Router do
  use DevpulseServerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    # plug :fetch_live_flash
    plug :put_root_layout, html: {DevpulseServerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :cli_auth do
    plug DevpulseServerWeb.Plugs.AuthenticateAgent
  end

  scope "/", DevpulseServerWeb do
    pipe_through :browser

    get "/auth/cli/verify", CliAuthController, :show
    get "/auth/accept/invite", CliAuthController, :show
    post "/api/v1/cli/auth/verify", CliAuthController, :authorize
    post "/api/v1/cli/auth/accept", CliAuthController, :exchange
  end

  scope "/api/v1/cli/auth", DevpulseServerWeb do
    pipe_through :api

    post "/retrigger", CliAuthRetriggerController, :retrigger
    get "/status/:pairing_code", CliAuthController, :check_status
    post "/exchange", CliAuthController, :exchange
  end

  scope "/api/v1/cli", DevpulseServerWeb do
    pipe_through :api

    post("/agent/session", AgentSessionController, :create)
    post("/agent/heartbeats", HeartbeatController, :create)
  end

  scope "/api/v1/cli", DevpulseServerWeb do
    pipe_through [:api, :cli_auth]

    get "/teams", CliTeamController, :index
    get "/teams/:team_id/projects", CliProjectController, :index

    post "/metrics", CliMetricsController, :create
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:devpulse_server, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: DevpulseServerWeb.Telemetry
    end
  end
end
