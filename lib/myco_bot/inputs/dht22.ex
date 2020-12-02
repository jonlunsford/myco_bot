defmodule MycoBot.Inputs.DHT22 do
  require Logger

  @moduledoc """
  AM2303/DHT22 Temp/Humidity Sensor

  Datasheet: https://cdn-shop.adafruit.com/datasheets/Digital+humidity+and+temperature+sensor+AM2302.pdf
  """

  def init(config) do
    Logger.debug("Attempting to start DHT sensor: #{inspect(config)}")
    case DHT.start_polling(config.pin_number, :am2302, config.polling_period) do
      {:ok, pid} ->
        Logger.debug("Started DHT sensor")
        {:ok, pid}

      {:error, ex, message} ->
        Logger.debug("Error with DHT: #{inspect(ex)}, #{inspect(message)}")
        :telemetry.execute(
          [:myco_bot, :sensor, :error],
          %{},
          %{error: message, exception: ex}
        )
    end
  end
end
