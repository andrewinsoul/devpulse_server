# DevPulse CLI App Features

This document defines the expected feature set for the DevPulse CLI agent.
It is the product and behavior spec for the separate CLI project that will
talk to the DevPulse web platform.

## Purpose

The CLI agent is the developer-facing runtime that runs on a developer's
machine, collects local telemetry, and sends it to DevPulse with minimal
overhead.

The CLI must support:

- Team-scoped handshake and authentication
- High-frequency heartbeat ingestion
- Multi-team developer workflows
- Safe local state management
- Reliable retry behavior when offline or when the server is temporarily unreachable

## Core Product Goals

1. Verify a developer's master API token only during handshake.
2. Mint a short-lived session credential after a successful handshake.
3. Send all heartbeats with the session credential, not the master token.
4. Ensure every heartbeat is attributed to the correct team.
5. Keep heartbeat collection fast and lightweight.

## Required Features

### 1. Handshake Flow

The CLI must be able to initiate a handshake with the server using:

- Master API token
- Hardware fingerprint
- Hostname
- Operating system
- Team context or team selector

The handshake must:

- Validate the master API token
- Verify that the developer belongs to the requested team
- Upsert or refresh the active agent session
- Receive a short-lived session credential from the server

The CLI must persist the session credential locally for reuse until expiry.

### 2. Team Selection

The CLI must support developers who belong to multiple teams.

The CLI should be able to identify which team a given workspace belongs to by
using one or more of the following:

- Explicit team selection by the user
- Repo-local configuration
- Team slug
- Git remote URL mapping

The CLI must never guess the team purely from the developer identity.

If a workspace can map to more than one team, the CLI should require an
explicit choice and remember that selection for the workspace.

### 3. Heartbeat Ingestion

The CLI must continuously send heartbeat events after handshake success.

Each heartbeat should include only local state that is relevant for telemetry,
such as:

- Project name
- Git branch
- Repo path
- Whether the working tree has uncommitted changes

Heartbeats must use the short-lived session credential.

The CLI should not send the master API token during heartbeat submission.

### 4. Offline Buffering and Retry

The CLI should tolerate temporary network loss.

Required behavior:

- Buffer heartbeats locally when the server is unavailable
- Retry with backoff
- Re-send queued heartbeats after reconnecting
- Drop or expire buffered items only based on explicit retention rules

The retry policy should avoid aggressive request storms.

### 5. Session Renewal

The CLI must detect session expiry and renew the session by re-running the
handshake.

Renewal should happen automatically when possible.

The CLI should also expose a way for the user to force a re-handshake.

### 6. Local Configuration

The CLI should support persistent configuration for:

- DevPulse server base URL
- Master API token
- Default team or workspace mapping
- Heartbeat interval
- Offline buffer retention
- Logging verbosity

Configuration should be stored locally and should be easy to inspect and update.

### 7. Security and Privacy

The CLI must:

- Keep the master API token out of the hot path
- Store secrets securely where possible
- Avoid leaking sensitive workspace details in logs
- Treat repo paths as sensitive data unless the product explicitly decides otherwise

The session credential should be short-lived and team-scoped.

### 8. Observability

The CLI should provide basic operational feedback:

- Whether handshake succeeded
- Which team/session is active
- Whether heartbeats are currently flowing
- Whether the CLI is offline and buffering
- When the session token is expiring or has expired

Logs should be useful for debugging without being noisy.

## Recommended Command Surface

These commands are suggested as a clean baseline:

- `devpulse init`
- `devpulse login`
- `devpulse whoami`
- `devpulse team select`
- `devpulse status`
- `devpulse start`
- `devpulse stop`
- `devpulse config get`
- `devpulse config set`

The exact command names can differ, but the CLI should support these
capabilities.

## Recommended Workflow

1. Developer installs the CLI.
2. Developer configures the server URL and master API token.
3. Developer selects the team for the current workspace.
4. CLI performs handshake.
5. Server returns short-lived session credential.
6. CLI emits heartbeats for that workspace and team.
7. If the token expires, CLI re-handshakes automatically.

## Data Model Expectations

The CLI should assume the server enforces the following concepts:

- A developer can belong to multiple teams.
- A handshake is always tied to a specific team.
- A session token belongs to exactly one team and one agent session.
- Heartbeats are append-only events bound to that session.

## Failure Handling

The CLI should handle these cases cleanly:

- Invalid master API token
- Developer not a member of requested team
- Expired session token
- Server unavailable
- Missing local configuration
- Ambiguous team mapping for a workspace

Failure messages should be direct and actionable.

## Non-Goals

The CLI should not:

- Render dashboards
- Query or mutate unrelated team data
- Re-verify the master API token on every heartbeat
- Infer a team from only the developer identity

## Implementation Priority

Priority order for the CLI project:

1. Handshake and session minting
2. Team selection and workspace mapping
3. Heartbeat loop
4. Offline buffering
5. Session renewal
6. Config and UX polish

