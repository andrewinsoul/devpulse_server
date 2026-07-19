defmodule DevpulseServerWeb.Router do
  use DevpulseServerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :cli_api do
    plug :accepts, ["json"]
    plug DevpulseServerWeb.Plugs.AuthenticateAgent
  end

  scope "/api/v1/cli", DevpulseServerWeb do
    pipe_through :api

    post("/agent/session", AgentSessionController, :create)
    post("/agent/heartbeats", HeartbeatController, :create)
  end

  scope "/api/v1/cli", DevpulseServerWeb do
    pipe_through :cli_api

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
