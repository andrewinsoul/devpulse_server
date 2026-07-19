defmodule DevpulseServerWeb.CliMetricsController do
  use DevpulseServerWeb, :controller

  def create(conn, %{"heartbeat" => heartbeat_params}) do
    actor = conn.assigns.current_actor

    DevpulseServer.Activity.Heartbeat
    |> Ash.Changeset.for_create(:create, heartbeat_params, actor: actor)
    |> Ash.create()
    |> case do
      {:ok, _heartbeat} ->
        conn
        |> put_status(:created)
        |> json(%{status: "success", message: "Heartbeat acknowledged"})

      {:error, error} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{status: "error", details: Ash.Error.to_error_class(error)})
    end
  end
end
