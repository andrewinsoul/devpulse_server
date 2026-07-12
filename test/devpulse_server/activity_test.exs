defmodule DevpulseServer.ActivityTest do
  use ExUnit.Case, async: true

  test "ping rejects missing session credentials" do
    assert {:error, :missing_session_token} = DevpulseServer.Activity.ping(%{})
  end
end
