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

## Agent authentication and project assignment

The server is the source of truth for the developer’s team/project assignment. A team lead creates an invitation containing both `team_id` and `project_id`. The project must belong to the selected team.

The current flow is:

1. The developer opens the invitation link and accepts it in the browser.
2. The server creates the developer profile and team membership.
3. The developer runs `devpulse login --token <invite-token>`.
4. The server exchanges the accepted invitation for a PAT and returns the assigned team, project, and assignment metadata.
5. The CLI stores the PAT globally and uses the assignment during `devpulse init`.
6. `devpulse init` verifies the local repository’s `origin` against the assigned project remote and writes the workspace configuration. It does not ask the developer to select a project.
7. `devpulse start` sends the PAT and project ID to the handshake endpoint.
8. The server verifies the PAT, project, and team membership, then returns a short-lived session token.
9. The CLI uses the session token for heartbeat requests.

`init` and `start` remain separate commands. The server does not accept a client-supplied project override during initialization; the invitation assignment is authoritative.

### CLI API endpoints

The agent uses these API endpoints under `/api/v1`:

- `POST /cli/auth/exchange` — exchange an accepted invitation for a PAT and assignment.
- `POST /cli/auth/retrigger` — start browser authorization when reauthentication is required.
- `GET /cli/auth/status/:pairing_code` — poll browser authorization status.
- `POST /cli/agent/handshake` — exchange the PAT for a short-lived session token scoped to a project.
- `POST /cli/agent/heartbeats` — submit Git/repository activity using the session token.

The server must be running for the DevPulse Agent to authenticate, establish sessions, and deliver heartbeats.

For the full sequential flow, see [`docs/test_flow.md`](docs/test_flow.md).

## Project Status
DevPulse Server is under active development.

The current focus is the core domain, agent lifecycle, and heartbeat pipeline, followed by the team-facing DevPulse web application.
