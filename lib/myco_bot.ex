defmodule MycoBot do
  require Logger

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def update_state(new_state) do
    GenServer.call(__MODULE__, {:update_state, new_state})
  end

  def report_state() do
    GenServer.call(__MODULE__, :report_state)
  end

  @impl true
  def init(args) do
    send(self(), :start)

    {:ok, args}
  end

  @impl true
  def handle_info(:start, state) do
    MycoBot.Telemetry.start_ht_sensor("i2c-1", state.ht_sensor_polling_period)

    Enum.each(state.devices, fn pin -> MycoBot.Relay.open_pin(pin) end)

    :telemetry.execute([:myco_bot, :started], %{}, state)

    {:noreply, state}
  end

  @impl true
  def handle_call({:update_state, new_state}, _from, state) do
    Logger.debug("[MYCOBOT] updating state: #{inspect(new_state)}")

    {:noreply, Map.merge(state, new_state)}
  end

  @impl true
  def handle_call(:report_state, _from, state) do
    Logger.debug("[MYCOBOT] reporting state: #{inspect(state)}")

    :telemetry.execute([:myco_bot, :state, :broadcast], %{}, state)

    {:reply, state, state}
  end
end
