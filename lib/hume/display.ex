defmodule Hume.Display do
  require Logger
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(args) do
    {:ok, font} = Chisel.Font.load(Application.app_dir(:hume, ["priv", "static", args.font]))

    Logger.debug("[HUME] Starting Display")

    {:ok, %{font: font}}
  end

  def set(params) do
    GenServer.cast(__MODULE__, params)
  end

  @impl true
  def handle_cast(%{text: text, x: x, y: y}, state) do
    Logger.debug("[HUME] Displaying: #{text} at x: #{x} y: #{y}")
    Hume.OLED.write(text, x, y, state.font)
    {:noreply, state}
  end
end
