defmodule MycoBot.Environment do
  require Logger

  use GenServer

  def start_link(options) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  def fetch(config_key) do
    GenServer.call(MycoBot.Environment, {:fetch, config_key})
  end

  def set(key, value) do
    GenServer.call(MycoBot.Environment, {:put, key, value})
  end

  def report_state() do
    config = GenServer.call(MycoBot.Environment, :report_state)

    :telemetry.execute([:myco_bot, :environment, :sync], %{}, %{config: config})
  end

  @impl true
  def init(options) do
    config =
      options
      |> Enum.into(%{})
      |> Map.put_new(:min_humidity, 70)
      |> Map.put_new(:max_humidity, 90)
      |> Map.put_new(:min_temp, 50)
      |> Map.put_new(:max_temp, 80)

    {:ok, config}
  end

  @impl true
  def handle_call({:fetch, config_key}, _from, config) do
    case Map.fetch(config, config_key) do
      {:ok, value} ->
        {:reply, value, config}
      :error ->
        {:reply, {:error, "Config key #{config_key} does not exist"}, config}
    end
  end

  @impl true
  def handle_call({:put, config_key, value}, _from, config) do
    new_config = Map.put(config, config_key, value)

    {:reply, :ok, new_config}
  end

  @impl true
  def handle_call(:report_state, _from, config) do
    {:reply, config, config}
  end
end
