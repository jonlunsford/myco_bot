defmodule MycoBot.GPIO do
  require Logger
  use GenServer

  alias Circuits.GPIO

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: via_name(args.pin))
  end

  @impl true
  def init(args) do
    state =
      args
      |> Map.put(:ref, nil)
      |> Map.put(:status, nil)

    case GPIO.open(state.pin, state.direction, [initial_value: state.value]) do
      {:ok, ref} ->
        state = %{state | ref: ref, status: polarized_status(state)}

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

  def toggle(pin_number) do
    via_name(pin_number)
    |> GenServer.whereis()
    |> case do
      nil -> {:error, :not_found}
      pid -> GenServer.call(pid, :toggle)
    end
  end

  def report_state(pid) do
    GenServer.call(pid, :report_state)
  end

  @impl true
  def handle_call(:report_state, _from, state) do
    Logger.debug("[MYCOBOT] reporting state: #{inspect(state)}")

    {:reply, state, state}
  end

  @impl true
  def handle_call(:up, _from, %{value: 1, polarity: :standard} = state) do
    # already up, noop
    {:reply, :already_up, state}
  end

  @impl true
  def handle_call(:up, _from, %{value: 0, polarity: :reverse} = state) do
    # already up, noop
    {:reply, :already_up, state}
  end

  @impl true
  def handle_call(:down, _from, %{value: 0, polarity: :standard} = state) do
    # already down, noop
    {:reply, :already_down, state}
  end

  @impl true
  def handle_call(:down, _from, %{value: 1, polarity: :reverse} = state) do
    # already down, noop
    {:reply, :already_down, state}
  end

  @impl true
  def handle_call(cmd, _from, state) do
    value = polarized_value(cmd, state)

    case GPIO.write(state.ref, value) do
      :ok ->
        state = %{state | value: value}
        state = %{state | status: polarized_status(state)}

        :telemetry.execute([:myco_bot, :gpio, cmd], %{}, state)

        {:reply, :ok, state}

      {:error, reason} ->
        state = Map.put(state, :error, reason)

        :telemetry.execute([:myco_bot, :gpio, :error], %{}, state)

        {:reply, :error, state}
    end
  end

  defp polarized_value(:up, state) do
    case state.polarity do
      :reverse -> 0
      :standard -> 1
    end
  end

  defp polarized_value(:down, state) do
    case state.polarity do
      :reverse -> 1
      :standard -> 0
    end
  end

  defp polarized_value(:toggle, state) do
    case state.value do
      0 -> 1
      1 -> 0
    end
  end

  defp polarized_status(%{polarity: :reverse} = state) do
    case state.value do
      1 -> :down
      0 -> :up
    end
  end

  defp polarized_status(%{polarity: :standard} = state) do
    case state.value do
      1 -> :up
      0 -> :down
    end
  end

  defp via_name(pin) do
    {:via, Registry, {MycoBot.Pins, "gpio#{pin}"}}
  end
end
