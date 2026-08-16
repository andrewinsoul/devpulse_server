<p align="center">
  <img src="docs/devpulse-brand.jpeg" alt="DevPulse">
</p>

<p align="center">
  The central application behind DevPulse.
</p>

---

# DevPulse Server

DevPulse Server is the central application behind DevPulse.

It powers the API used by the DevPulse Agent and provides the foundation for a team-facing web application where organizations can manage developers, teams, projects, and development activity.

## Architecture

```text
                         DevPulse
                            │
              ┌─────────────┴─────────────┐
              │                           │
        DevPulse Agent              DevPulse Server
              │                           │
              └──────────► HTTP/API ◄─────┘
                                          │
                               ┌──────────┴──────────┐
                               │                     │
                            Web UI                  API
                               │                     │
                               └──────────┬──────────┘
                                          │
                                         Ash
                                          │
                                    PostgreSQL
```

## Responsibilities
- Developer onboarding and authentication
- Organizations, teams, and memberships
- Projects and developer management
- API token and agent session management
- Heartbeat ingestion and activity tracking
- Team-facing developer activity visibility

## Technology
- Elixir
- Phoenix
- Phoenix LiveView
- Ash Framework
- AshPostgres
- PostgreSQL

## Development
Install dependencies:

```bash
mix deps.get
```

Create and migrate the database:
```bash
mix ecto.create
mix ecto.migrate
```

Boot server
```bash
mix phx.server
```

Server should run on:
```bash
http://localhost:4000
```

## N.B
The DevPulse Agent uses these endpoints for authentication, handshakes, agent sessions, and heartbeat reporting. So this server needs to be running for the Devpulse Agent to work

## Project Status
DevPulse Server is under active development.

The current focus is the core domain, agent lifecycle, and heartbeat pipeline, followed by the team-facing DevPulse web application.