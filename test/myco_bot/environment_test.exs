defmodule MycoBot.EnvironmentTest do
  use ExUnit.Case, async: true

  alias MycoBot.Environment

  test "fetch/1" do
    assert Environment.fetch(:max_humidity) == 90
  end

  test "set/2" do
    :ok = Environment.set(:new_key, 1)

    assert Environment.fetch(:new_key) == 1
  end

  test "fetch max_humidity" do
    assert GenServer.call(Environment, {:fetch, :max_humidity}) == 90
  end

  test "fetch non-existent config key" do
    assert {:error, _message} = GenServer.call(Environment, {:fetch, :foo})
  end

  test "put new config" do
    :ok = GenServer.call(Environment, {:put, :new_key, "new_value"})

    assert GenServer.call(Environment, {:fetch, :new_key}) == "new_value"
  end

  test "update config" do
    :ok = GenServer.call(Environment, {:put, :new_key, "new_value"})
    :ok = GenServer.call(Environment, {:put, :new_key, "new_new_value"})

    assert GenServer.call(Environment, {:fetch, :new_key}) == "new_new_value"
  end
end
