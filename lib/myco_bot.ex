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
    state.inputs
    |> Enum.each(fn {mod, args} -> mod.init(args) end)

    state.outputs
    |> Enum.each(fn config -> MycoBot.Relay.open_pin(config) end)

    :telemetry.execute([:myco_bot, :started], %{}, state)

    {:noreply, state}
  end
end
