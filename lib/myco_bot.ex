defmodule MycoBot do
  require Logger

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(args) do
    send(self(), :start)

    {:ok, args}
  end


  @impl true
  def handle_info(:start, state) do
    MycoBot.Telemetry.start_ht_sensor("i2c-1", state.ht_sensor_polling_period)
    MycoBot.Relay.open_pin(%{pin_number: 16, pin_direction: :output, value: 1})

    :telemetry.execute([:myco_bot, :started], %{}, state)

    {:noreply, state}
  end
end
