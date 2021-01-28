defmodule MycoBot.Relay do
  require Logger

  @moduledoc """
  Dynamic supervisor to manage GPIO processes
  """
  use DynamicSupervisor

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def open_pin(args) do
    spec = MycoBot.GPIO.child_spec(args)

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def report_states do
    Logger.debug("[MYCOBOT] Fetching GPIO Relay states")

    states =
      DynamicSupervisor.which_children(__MODULE__)
      |> Enum.map(fn({:undefined, pid, _type, _modules}) ->
        MycoBot.GPIO.report_state(pid)
      end)

    Logger.debug("[MYCOBOT] reporting states: #{inspect(states)}")

    :telemetry.execute([:myco_bot, :gpio, :sync], %{}, %{devices: states})
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
