defmodule Hume do
  require Logger

  use GenServer

  alias Hume.Sensor
  #alias Hume.Display
  alias Hume.Power

  def start_link(arg) do
    Logger.debug("[HUME] Starting sensor polling")

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
    Logger.debug("[HUME] getting latest reading...")

    temp = Sensor.read_temp()
    rh = Sensor.read_rh()
    state = %{state | temp: temp, rh: rh}
    text = "RH: #{state.rh} T: #{state.temp}"

    Logger.debug("[HUME] Latest reading: " <> text)

    #Display.set(%{text: text, x: 1, y: 1})

    Power.handle_rh(rh)

    Process.send_after(self(), :poll, 30_000)

    {:noreply, state}
  end
end
