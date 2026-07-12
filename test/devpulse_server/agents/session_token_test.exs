defmodule DevpulseServer.Agents.SessionTokenTest do
  use ExUnit.Case, async: true

  alias DevpulseServer.Agents.SessionToken

  test "signs and verifies a short-lived session token" do
    session = %{
      id: Ecto.UUID.generate(),
      developer_profile_id: Ecto.UUID.generate(),
      team_id: Ecto.UUID.generate(),
      hardware_fingerprint: "fingerprint-123"
    }

    assert {:ok, token} = SessionToken.sign(session)
    assert {:ok, claims} = SessionToken.verify(token)

    assert claims["agent_session_id"] == session.id
    assert claims["developer_profile_id"] == session.developer_profile_id
    assert claims["team_id"] == session.team_id
    assert claims["hardware_fingerprint"] == session.hardware_fingerprint
  end
end
