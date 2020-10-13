defmodule MycoBot.Relay do
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
    states =
      DynamicSupervisor.which_children(__MODULE__)
      |> Enum.map(fn({:undefined, pid, _type, _modules}) ->
        MycoBot.GPIO.report_state(pid)
      end)

    IO.inspect(DynamicSupervisor.which_children(__MODULE__))

    :telemetry.execute([:myco_bot, :gpio, :sync], %{}, %{devices: states})
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
