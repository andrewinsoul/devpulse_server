defmodule DevpulseServerWeb.HeartbeatControllerTest do
  use ExUnit.Case, async: true

  alias DevpulseServerWeb.HeartbeatController

  test "returns unauthorized when the session token is missing" do
    conn = Plug.Test.conn(:post, "/api/v1/cli/agent/heartbeats", %{})
    conn = HeartbeatController.create(conn, %{})

    assert conn.status == 401

    assert %{"errors" => [%{"detail" => "Missing session token."}]} =
             Jason.decode!(conn.resp_body)
  end

  test "returns unauthorized when the session token is malformed" do
    conn = Plug.Test.conn(:post, "/api/v1/cli/agent/heartbeats", %{})
    conn = %{conn | req_headers: [{"authorization", "Bearer malformed-session-token"}]}
    conn = HeartbeatController.create(conn, %{})

    assert conn.status == 401

    assert %{"errors" => [%{"detail" => "Invalid or expired session token."}]} =
             Jason.decode!(conn.resp_body)
  end
end
