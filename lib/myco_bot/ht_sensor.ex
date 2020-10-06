defmodule MycoBot.HTSensor do
  @moduledoc """
  Humidity and temperature sensor reading.

  Using: https://github.com/adafruit/Adafruit_Si7021
  Datasheet: https://cdn-learn.adafruit.com/assets/assets/000/035/931/original/Support_Documents_TechnicalDocs_Si7021-A20.pdf
  """
  alias Circuits.I2C

  # Address where bits are written/read
  @default_addr 0x40
  @rh_hold_cmd <<0xE5>>
  @temp_hold_cmd <<0xE3>>
  @reset <<0xFE>>

  ## TBD implementation:
  #
  # @rh_no_hold_cmd <<0xF5>>
  # @temp_no_hold_cmd <<0xF3>>
  # @read_temp_cmd <<0xE0>> # Read temp from last RH measurement
  # @write_cmd <<0xE6>> # write RH/T user register 1
  # @read_cmd <<0xE7>> # read RH/T user register 1
  # @write_heater_cmd <<0x51>> # Write heater control register
  # @read_heater_cmd <<0x11>> # Read heater control register
  # @heater_reg_bit_cmd <<0x02>> # Control register bit
  # @id1_bit 0xFA0F # Read Electronic ID 1st byte
  # @id2_bit 0xFCC9 # Read Electronic ID 2nd byte
  # @rirmware_vsn_cmd <<0x84B8>>
  # @rev_1_cmd <<0xff>>
  # @rev_2_cmd <<0x20>>

  def open(i2c_bus) when is_bitstring(i2c_bus) do
    case I2C.open(i2c_bus) do
      {:ok, ref} ->
        I2C.write(ref, @default_addr, @reset)
        {:ok, ref}

      {:error, reason} ->
        :telemetry.execute(
          [:myco_bot, :ht_sensor, :error],
          %{},
          %{error: reason, i2c_bus: i2c_bus}
        )

        {:error, reason}
    end
  end
  def open(i2c_bus) do
    :telemetry.execute(
      [:myco_bot, :ht_sensor, :error],
      %{},
      %{i2c_bus: i2c_bus, error: "Could not start HTSensor."}
    )
  end

  def read(ref) when is_reference(ref) do
    read_temp(ref)
    read_rh(ref)
  end

  def read(ref) do
    :telemetry.execute(
      [:myco_bot, :ht_sensor, :error],
      %{},
      %{ref: ref, error: "Provided ref is incorrect."}
    )
  end

  def read_temp(ref) do
    case I2C.write_read(ref, @default_addr, @temp_hold_cmd, 2) do
      {:ok, bits} ->
        :telemetry.execute(
          [:myco_bot, :ht_sensor, :read_temp],
          %{temp: convert_temp(bits)},
          %{ref: ref, bits: bits}
        )

      {:error, reason} ->
        :telemetry.execute(
          [:myco_bot, :ht_sensor, :error],
          %{},
          %{ref: ref, error: reason}
        )
    end
  end

  def read_rh(ref) do
    case I2C.write_read(ref, @default_addr, @rh_hold_cmd, 2) do
      {:ok, bits} ->
        :telemetry.execute(
          [:myco_bot, :ht_sensor, :read_rh],
          %{rh: convert_rh(bits)},
          %{ref: ref, bits: bits}
        )

      {:error, reason} ->
        :telemetry.execute(
          [:myco_bot, :ht_sensor, :error],
          %{},
          %{ref: ref, error: reason}
        )
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
end
