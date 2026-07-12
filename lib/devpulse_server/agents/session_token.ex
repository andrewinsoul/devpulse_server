defmodule DevpulseServer.Agents.SessionToken do
  @moduledoc false

  @salt "devpulse-agent-session"
  @max_age 60 * 30

  def max_age, do: @max_age

  def sign(%{
        id: id,
        developer_profile_id: developer_profile_id,
        team_id: team_id,
        hardware_fingerprint: hardware_fingerprint
      }) do
    claims = %{
      "agent_session_id" => id,
      "developer_profile_id" => developer_profile_id,
      "team_id" => team_id,
      "hardware_fingerprint" => hardware_fingerprint
    }

    {:ok, Phoenix.Token.sign(DevpulseServerWeb.Endpoint, @salt, claims)}
  end

  def verify(token) when is_binary(token) do
    Phoenix.Token.verify(DevpulseServerWeb.Endpoint, @salt, token, max_age: @max_age)
  end
end
