defmodule MycoBot.GPIO do
  use GenServer

  alias Circuits.GPIO

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: via_name(args.pin_number))
  end

  @impl true
  def init(args) do
    state =
      args
      |> Map.put(:ref, nil)
      |> Map.put(:status, "offline")

    case GPIO.open(state.pin_number, state.pin_direction, [initial_value: state.value]) do
      {:ok, ref} ->
        state = %{state | ref: ref, status: "online"}

        :telemetry.execute([:myco_bot, :gpio, :opened], %{}, state)

        {:ok, state}

      {:error, reason} ->
        state = Map.put(state, :error, reason)

        :telemetry.execute([:myco_bot, :gpio, :error], %{}, state)

        {:error, state}
    end
  end

  def up(pin_number) do
    via_name(pin_number)
    |> GenServer.whereis()
    |> case do
      nil -> {:error, :not_found}
      pid -> GenServer.call(pid, :up)
    end
  end

  def down(pin_number) do
    via_name(pin_number)
    |> GenServer.whereis()
    |> case do
      nil -> {:error, :not_found}
      pid -> GenServer.call(pid, :down)
    end
  end

  def report_state(pid) do
    GenServer.call(pid, :report_state)
  end

  @impl true
  def handle_call(:up, _from, %{value: 0} = state) do
    case GPIO.write(state.ref, 1) do
      :ok ->
        state = %{state | value: 1}

        :telemetry.execute([:myco_bot, :gpio, :up], %{}, state)

        {:reply, :ok, state}

      {:error, reason} ->
        state = Map.put(state, :error, reason)

        :telemetry.execute([:myco_bot, :gpio, :error], %{}, state)

        {:reply, :error, state}
    end
  end

  @impl true
  def handle_call(:up, _from, %{value: 1} = state) do
    # already up, noop
    {:reply, :already_up, state}
  end

  @impl true
  def handle_call(:down, _from, %{value: 1} = state) do
    case GPIO.write(state.ref, 0) do
      :ok ->
        state = %{state | value: 0}

        :telemetry.execute([:myco_bot, :gpio, :down], %{}, state)

        {:reply, :ok, state}

      {:error, reason} ->
        state = Map.put(state, :error, reason)

        :telemetry.execute([:myco_bot, :gpio, :error], %{}, state)

        {:reply, :error, state}
    end
  end

  @impl true
  def handle_call(:down, _from, %{value: 0} = state) do
    # already down, noop
    {:reply, :already_down, state}
  end

  @impl true
  def handle_call(:report_state, _from, state) do
    {:reply, state, state}
  end

  defp via_name(pin_number) do
    {:via, Registry, {Pins, "gpio#{pin_number}"}}
  end
end
