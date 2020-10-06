defmodule MycoBot.Instrumenter do
  require Logger

  def setup do
    events = [
      [:myco_bot, :ht_sensor, :error],
      [:myco_bot, :ht_sensor, :read_temp],
      [:myco_bot, :ht_sensor, :read_rh],
    ]

    :telemetry.attach_many(
      "mycobot-instrumenter",
      events,
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event(event, measurements, meta, _config) do
    Logger.debug("Event: #{inspect(event)}")
    Logger.debug("Measurements: #{inspect(measurements)}")
    Logger.debug("Meta: #{inspect(meta)}")
  end
end
