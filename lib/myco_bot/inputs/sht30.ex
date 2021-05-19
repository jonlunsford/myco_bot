defmodule MycoBot.Inputs.SHT30 do
  require Logger

  @moduledoc """
  Temperature/Humidity Sensor

  Using: https://www.adafruit.com/product/4099
  Datasheet: https://www.sensirion.com/fileadmin/user_upload/customers/sensirion/Dokumente/2_Humidity_Sensors/Datasheets/Sensirion_Humidity_Sensors_SHT3x_Datasheet_digital.pdf
  """

  defstruct description: "Adafruit SHT30 Temperature/Humidity sensor"

  alias Circuits.I2C

  @i2c_addr 0x44

  #@soft_reset <<0x30, 0xA2>>
  @enable_periodic_mode <<0x21, 0x30>>
  @read <<0xE0, 0x00>>

  def init(config) do
    case I2C.open(config.bus_name) do
      {:ok, ref} ->
        #I2C.write(ref, @i2c_addr, @soft_reset)
        I2C.write(ref, @i2c_addr, @enable_periodic_mode)

        MycoBot.Telemetry.start_poller(
          measurements: [{__MODULE__, :read, [ref]}],
          period: :timer.seconds(config.polling_period),
          name: :sht30
        )

        {:ok, ref}

      {:error, reason} ->
        telemetry(:error, %{}, %{error: reason})
        {:error, reason}
    end
  end

  def read(ref) when is_reference(ref) do
    case I2C.write_read(ref, @i2c_addr, @read, 6) do
      {:ok, <<temp::binary-size(2), _, rh::binary-size(2), _>>} ->
        telemetry(
          :read,
          %{
            temperature: convert_binary_temperature(temp),
            humidity: convert_binary_humidity(rh)
          }
        )

      {:error, reason} ->
        telemetry(:error, %{}, %{error: reason})
        {:error, reason}
    end
  end

  # Page 14
  defp convert_binary_temperature(bits) do
    value = :binary.decode_unsigned(bits)
    Logger.debug("[MYCOBOT] calculating temperature: #{value}")

    (-49 + 315 * value / :math.pow(2, 16) - 1)
    |> Float.round(2)
  end

  # Page 14
  defp convert_binary_humidity(bits) do
    value = :binary.decode_unsigned(bits)
    Logger.debug("[MYCOBOT] calculating humidity: #{value}")

    (100 *
       value /
       (:math.pow(2, 16) - 1))
    |> Float.round(2)
  end

  defp telemetry(event, metrics, meta \\ %{}) do
    meta = Map.put(meta, :module, __MODULE__)
    :telemetry.execute([:myco_bot, :sht30, event], metrics, meta)
  end
end
