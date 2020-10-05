defmodule MycoBot do
  require Logger

  use GenServer

  alias MycoBot.Sensor
  # alias MycoBot.Display
  alias MycoBot.Power

  def start_link(arg) do
    Logger.debug("[MYCO] Starting sensor polling")

    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    state = %{
      rh: nil,
      temp: nil
    }

    send(self(), :poll)

    {:ok, state}
  end

  def handle_info(:poll, state) do
    Logger.debug("[MYCO] getting latest reading...")

    temp = Sensor.read_temp()
    rh = Sensor.read_rh()
    state = %{state | temp: temp, rh: rh}
    text = "RH: #{state.rh} T: #{state.temp}"

    Logger.debug("[MYCO] Latest reading: " <> text)

    # Display.set(%{text: text, x: 1, y: 1})

    Power.handle_rh(rh)

    :telemetry.execute(
      [:myco_bot, :sensor],
      %{temp: temp, rh: rh},
      %{}
    )

    Process.send_after(self(), :poll, 30_000)

    {:noreply, state}
  end
end
