defmodule DevpulseServerWeb.HeartbeatControllerTest do
  use DevpulseServerWeb.ConnCase, async: true

  test "returns unauthorized when the session token is missing", %{conn: conn} do
    conn = post(conn, ~p"/api/agent/heartbeats", %{})

    assert %{"errors" => [%{"detail" => "Missing session token."}]} = json_response(conn, 401)
  end
end
