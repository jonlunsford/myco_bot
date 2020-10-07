defmodule MycoBot.Telemetry do
  @moduledoc false

  use DynamicSupervisor

  alias MycoBot.HTSensor

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_ht_sensor(i2c_bus, period \\ 30) do
    case HTSensor.open(i2c_bus) do
      {:ok, ref} ->
        telemetry_opts = [
          measurements: [{HTSensor, :read, [ref]}],
          period: :timer.seconds(period),
          name: via_name(i2c_bus)
        ]

        spec = :telemetry_poller.child_spec(telemetry_opts)

        DynamicSupervisor.start_child(__MODULE__, spec)

      {:error, reason} ->
        {:error, reason}
    end
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
    {:via, Registry, {Pollers, key}}
  end
end
