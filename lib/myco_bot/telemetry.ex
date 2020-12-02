defmodule MycoBot.Telemetry do
  @moduledoc false

  use DynamicSupervisor

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_poller(opts) do
    spec = :telemetry_poller.child_spec(opts)

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop_poller(key) do
    via_name(key)
    |> GenServer.whereis()
    |> case do
      nil -> {:error, :not_found}
      poller -> DynamicSupervisor.terminate_child(__MODULE__, poller)
    end
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp via_name(key) do
    {:via, Registry, {MycoBot.Pollers, key}}
  end
end
