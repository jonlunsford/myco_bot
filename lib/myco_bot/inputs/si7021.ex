defmodule MycoBot.Inputs.SI7021 do
  @moduledoc """
  Humidity and temperature sensor reading.

  Using: https://github.com/adafruit/Adafruit_Si7021
  Datasheet: https://cdn-learn.adafruit.com/assets/assets/000/035/931/original/Support_Documents_TechnicalDocs_Si7021-A20.pdf
  """

  defstruct description: "Adafruit SI7021 Humidity/Temp sensor"

  alias Circuits.I2C

  # Address where bits are written/read
  @addr 0x40
  @rh_hold_cmd <<0xE5>>
  @temp_hold_cmd <<0xE3>>
  @reset <<0xFE>>

  def init(config) do
    case I2C.open(config.bus_name) do
      {:ok, ref} ->
        I2C.write(ref, @addr, @reset)

        MycoBot.Telemetry.start_poller(
          measurements: [{__MODULE__, :read, [ref]}],
          period: :timer.seconds(config.polling_period),
          name: :si7021
        )

        {:ok, ref}

      {:error, reason} ->
        telemetry(:error, %{}, %{error: reason})
        {:error, reason}
    end
  end

  def close(i2c_bus) do
    I2C.close(i2c_bus)
  end

  def read(ref) when is_reference(ref) do
    read_temp(ref)
    read_rh(ref)
  end

  def read(ref) do
    telemetry(:error, %{}, %{ref: ref, error: "Provided ref is incorrect."})
  end

  def read_temp(ref) do
    case I2C.write_read(ref, @addr, @temp_hold_cmd, 2) do
      {:ok, bits} ->
        telemetry(:temerature, %{temperature: convert_temp(bits)}, %{ref: ref, bits: bits})

      {:error, reason} ->
        telemetry(:error, %{}, %{ref: ref, error: reason})
    end
  end

  def read_rh(ref) do
    case I2C.write_read(ref, @addr, @rh_hold_cmd, 2) do
      {:ok, bits} ->
        telemetry(:humidity, %{humidity: convert_rh(bits)}, %{ref: ref, bits: bits})

      {:error, reason} ->
        telemetry(:error, %{}, %{ref: ref, error: reason})
    end
  end

  defp convert_temp(bits) when is_bitstring(bits) do
    reading = :binary.decode_unsigned(bits)
    # See page 22 of datasheet for formula
    value = reading * 175.72 / 65536 - 46.85

    value
    |> celcius_to_f
    |> Float.round()
  end
  defp convert_temp(_), do: 0.0

  defp celcius_to_f(temp) when is_float(temp) do
    temp / 5 * 9 + 32
  end
  defp celcius_to_f(_), do: 0.0

  defp convert_rh(bits) when is_bitstring(bits) do
    reading = :binary.decode_unsigned(bits)
    # See page 21 of datasheet for formula
    value = reading * 125 / 65536 - 6

    value
    |> Float.round()
  end

  defp telemetry(event, metrics, meta) do
    meta = Map.put(meta, :module, __MODULE__)
    :telemetry.execute([:myco_bot, :si7021, event], metrics, meta)
  end
end
