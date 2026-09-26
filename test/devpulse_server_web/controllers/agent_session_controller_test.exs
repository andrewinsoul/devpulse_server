defmodule DevpulseServerWeb.AgentSessionControllerTest do
  use ExUnit.Case, async: true

  alias DevpulseServerWeb.AgentSessionController

  test "returns unauthorized when the PAT is missing" do
    conn = Plug.Test.conn(:post, "/api/v1/cli/agent/handshake", %{})
    conn = AgentSessionController.handshake(conn, %{})

    assert conn.status == 401

    assert %{
             "status" => "error",
             "details" => "Missing or invalid Authorization header."
           } = Jason.decode!(conn.resp_body)
  end
end
