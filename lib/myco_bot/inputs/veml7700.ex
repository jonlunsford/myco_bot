defmodule MycoBot.Inputs.VEML7700 do
  require Logger

  @moduledoc """
  Ambient Light Sensor

  Using: https://learn.adafruit.com/adafruit-veml7700/overview
  Datasheet: https://www.vishay.com/docs/84286/veml7700.pdf
  Porting: https://github.com/adafruit/Adafruit_CircuitPython_VEML7700
  """

  defstruct description: "Adafruit VEML7700 Ambient Light Sensor"

  use Bitwise

  alias Circuits.I2C

  @i2c_addr 0x10

  # Values relevant to configuration register #0
  # See page #5 of datasheet above

  # Command Registers
  @als_read <<0x04>>
  @white_read <<0x05>>
  @als_enable <<0x00, 0x00>>
  @als_disable <<0x00, 0x01>>
  @psm_disable <<0x03, 0x00>>

  def init(config) do
    case I2C.open(config.bus_name) do
      {:ok, ref} ->
        I2C.write(ref, @i2c_addr, @als_disable)
        I2C.write(ref, @i2c_addr, <<0x00, gain_to_binary(config.gain)>>)
        I2C.write(ref, @i2c_addr, <<0x00, integration_time_to_binary(config.integration_time)>>)
        I2C.write(ref, @i2c_addr, @psm_disable)
        I2C.write(ref, @i2c_addr, @als_enable)

        config = Map.put(config, :ref, ref)

        MycoBot.Telemetry.start_poller(
          measurements: [{__MODULE__, :read, [config]}],
          period: :timer.seconds(config.polling_period),
          name: :veml7700
        )

        {:ok, ref}

      {:error, reason} ->
        telemetry(:error, %{}, %{error: reason})
        {:error, reason}
    end
  end

  def read(config) do
    with {:ok, lux} <- read_lux(config),
         {:ok, white} <- read_white(config) do
      telemetry(:read, %{lux: Float.round(lux, 2), white: Float.round(white, 2)}, config)
    else
      {:error, reason} ->
        telemetry(:error, %{}, %{error: reason})
    end
  end

  def read_lux(config) do
    case I2C.write_read(config.ref, @i2c_addr, @als_read, 2) do
      {:ok, bits} ->
        lux = :binary.decode_unsigned(bits) * resolution(config)

        {:ok, lux}

      {:error, reason} ->
        telemetry(:error, %{}, %{error: reason})
        {:error, reason}
    end
  end

  def read_white(config) do
    case I2C.write_read(config.ref, @i2c_addr, @white_read, 2) do
      {:ok, bits} ->
        {:ok, :binary.decode_unsigned(bits)}

      {:error, reason} ->
        telemetry(:error, %{}, %{error: reason})
        {:error, reason}
    end
  end

  # Page #7
  defp resolution(config) do
    max_resolution = 0.0036
    max_gain = 2
    max_integration_time = 800

    max_resolution *
      (max_integration_time / config.integration_time) *
      (max_gain / config.gain)
  end

  # Register Name: ALS_GAIN
  # Bit: 12:11
  # Description: gain setting, page #5
  defp gain_to_binary(gain) do
    [
      {1, 0x0},
      {2, 0x1},
      {0.125, 0x2},
      {0.25, 0x3}
    ]
    |> Enum.find_value(fn {key, value} ->
      if key == gain, do: value
    end) <<< 11
  end

  # Register Name: ALS_IT
  # Bit: 9:6
  # Description: integration time setting, page #5
  defp integration_time_to_binary(time_millis) when is_integer(time_millis) do
    [
      {25, 0xC},
      {50, 0x8},
      {100, 0x0},
      {200, 0x1},
      {400, 0x2},
      {800, 0x3}
    ]
    |> Enum.find_value(fn {key, value} ->
      if key == time_millis, do: value
    end) <<< 6
  end

  # Register Name: ALS_PERS
  # Bit: 5:4
  # Description: persistence protect number setting, page #5
  # defp persistence_to_binary(setting) when is_integer(setting) do
  # [
  # {1, 0x0},
  # {2, 0x1},
  # {3, 0x2},
  # {4, 0x3}
  # ]
  # |> Enum.find_value(fn {key, value} ->
  # if key == setting, do: value
  # end) <<< 4
  # end

  defp telemetry(event, metrics, meta) do
    meta = Map.put(meta, :module, __MODULE__)
    :telemetry.execute([:myco_bot, :veml7700, event], metrics, meta)
  end
end
