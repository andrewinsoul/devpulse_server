defmodule DevpulseServer.TokenCache do
  @moduledoc """
  An in-memory, TTL-backed cache for short-lived token exchanges (e.g. CLI pairing).
  Uses an ETS table for O(1) concurrent reads and a periodic cleanup sweep.
  """
  use GenServer

  @table :devpulse_token_cache
  @sweep_interval :timer.minutes(1)

  # --- Client API ---

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Stores a key-value pair in the cache.

  ## Options
    * `:ttl` - Time-To-Live in milliseconds. Default: 15 minutes.
  """
  def put(key, value, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, :timer.minutes(15))
    expires_at = System.system_time(:second) + div(ttl, 1000)

    :ets.insert(@table, {key, value, expires_at})
    :ok
  end

  @doc """
  Retrieves a value by key. Returns `nil` if missing or expired.
  """
  def get(key) do
    now = System.system_time(:second)

    case :ets.lookup(@table, key) do
      [{^key, value, expires_at}] when expires_at > now ->
        value

      [{^key, _value, _expires_at}] ->
        delete(key)
        nil

      [] ->
        nil
    end
  end

  @doc """
  Retrieves the status payload for a given pairing code.
  """
  def get_pairing_status(pairing_code) when is_binary(pairing_code) do
    case get(pairing_code) do
      nil -> {:error, :not_found}
      data -> {:ok, data}
    end
  end

  @doc """
  Deletes a pairing code entry from the cache once consumed.
  """
  def delete_pairing_code(pairing_code) when is_binary(pairing_code) do
    delete(pairing_code)
  end

  @doc """
  Deletes a key from the cache (e.g., after one-time consumption).
  """
  def delete(key) do
    :ets.delete(@table, key)
    :ok
  end

  # --- Server Callbacks ---

  @impl true
  def init(_opts) do
    :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])

    schedule_sweep()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:sweep, state) do
    now = System.system_time(:second)

    match_spec = [{{:"$1", :"$2", :"$3"}, [{:"=<", :"$3", now}], [true]}]
    :ets.select_delete(@table, match_spec)

    schedule_sweep()
    {:noreply, state}
  end

  defp schedule_sweep do
    Process.send_after(self(), :sweep, @sweep_interval)
  end
end
