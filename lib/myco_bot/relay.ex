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

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
