defmodule DevpulseServer.ActivityTest do
  use ExUnit.Case, async: true

  test "ping rejects a missing session token" do
    assert {:error, :invalid_session_token} = DevpulseServer.Activity.ping(%{}, nil)
  end

  test "ping rejects an invalid session token before touching the database" do
    assert {:error, :invalid_session_token} =
             DevpulseServer.Activity.ping(%{"session_id" => "session-1"}, "invalid-token")
  end
end
