defmodule MycoBot.Power do
  require Logger

  use GenServer

  alias Circuits.GPIO

  @rh_threshold 98

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    state = %{ref: nil, pin: 16, status: :down}

    case GPIO.open(state.pin, :output) do
      {:ok, ref} ->
        Logger.debug("[MYCO] GPIO pin found")
        {:ok, %{state | ref: ref}}

      {:error, reason} ->
        Logger.warn("[MYCO] Error with GPIO: #{reason}")
        {:ok, state}
    end
  end

  def up do
    Logger.debug("[MYCO] power up")
    GenServer.call(__MODULE__, :up)
  end

  def down do
    Logger.debug("[MYCO] power down")
    GenServer.call(__MODULE__, :down)
  end

  def handle_rh(rh) when is_float(rh) do
    Logger.debug("[MYCO] handling rh: #{rh}")

    if rh >= @rh_threshold, do: down(), else: up()
  end

  def handle_rh(rh), do: Logger.debug("[MYCO] could not handle rh reading: #{rh}")

  @impl true
  def handle_call(:up, _from, %{status: :down} = state) do
    response = GPIO.write(state.ref, 1)

    :telemetry.execute(
      [:myco_bot, :power, :up],
      %{},
      %{gpio_response: response}
    )

    {:reply, response, %{state | status: :up}}
  end

  @impl true
  def handle_call(:up, _from, %{status: :up} = state) do
    Logger.debug("[MYCO] power is already up, noop.")
    {:reply, %{}, state}
  end

  @impl true
  def handle_call(:down, _from, %{status: :up} = state) do
    response = GPIO.write(state.ref, 0)

    :telemetry.execute(
      [:myco_bot, :power, :down],
      %{},
      %{gpio_response: response}
    )

    {:reply, response, %{state | status: :down}}
  end

  @impl true
  def handle_call(:down, _from, %{status: :down} = state) do
    Logger.debug("[MYCO] power is already down, noop.")
    {:reply, %{}, state}
  end
end
