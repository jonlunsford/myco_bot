defmodule MycoBot.Instrumenter do
  require Logger

  def setup do
    events = [
      [:myco_bot, :started],

      [:myco_bot, :ht_sensor, :error],
      [:myco_bot, :ht_sensor, :read_temp],
      [:myco_bot, :ht_sensor, :read_rh],

      [:myco_bot, :gpio, :error],
      [:myco_bot, :gpio, :opened],
      [:myco_bot, :gpio, :up],
      [:myco_bot, :gpio, :down]
    ]

    :telemetry.attach_many(
      "mycobot-instrumenter",
      events,
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event([:myco_bot, :ht_sensor, :read_rh], measurements, meta, _config) do
    Logger.debug("[MYCOBOT] measurements: #{inspect(measurements)}")
    Logger.debug("[MYCOBOT] meta: #{inspect(meta)}")

    if measurements.rh >= 90, do: MycoBot.GPIO.down(16), else: MycoBot.GPIO.up(16)
  end

  def handle_event(event, measurements, meta, _config) do
    Logger.debug("[MYCOBOT] event: #{inspect(event)}")
    Logger.debug("[MYCOBOT] measurements: #{inspect(measurements)}")
    Logger.debug("[MYCOBOT] meta: #{inspect(meta)}")
  end
end
