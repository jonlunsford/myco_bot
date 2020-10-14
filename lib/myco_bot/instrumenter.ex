defmodule MycoBot.Instrumenter do
  require Logger

  def setup do
    events = [
      # [:myco_bot, :started],

      [:myco_bot, :ht_sensor, :error],
      # [:myco_bot, :ht_sensor, :read_temp],
      [:myco_bot, :ht_sensor, :read_rh],

      # [:myco_bot, :gpio, :error],
      # [:myco_bot, :gpio, :opened],
      # [:myco_bot, :gpio, :up],
      # [:myco_bot, :gpio, :down],
      # [:myco_bot, :gpio, :sync],

      [:myco_bot_ui, :device, :refresh],
      [:myco_bot_ui, :device, :change]
      # [:myco_bot_ui, :dashboard, :mounted]
    ]

    :telemetry.attach_many(
      "mycobot-instrumenter",
      events,
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event([:myco_bot, :ht_sensor, :read_rh], measurements, _meta, _config) do
    if measurements.rh >= 95,
      do: MycoBot.GPIO.down(16),
      else: MycoBot.GPIO.up(16)
  end

  def handle_event([:myco_bot, :ht_sensor, :error], _measurements, _meta, _config) do
    MycoBot.Telemetry.restart_ht_sensor("i2c-1")
  end

  def handle_event([:myco_bot_ui, :device, :refresh], _measurements, _meta, _config) do
    MycoBot.Relay.report_states()
  end

  def handle_event([:myco_bot_ui, :device, :change], _measurements, meta, _config) do
    Logger.debug("[MYCOBOT] [:myco_bot_ui, :device, :change]: #{inspect(meta)}")

    if meta.value == 1,
      do: MycoBot.GPIO.up(meta.pin_number),
      else: MycoBot.GPIO.down(meta.pin_number)
  end

  def handle_event(event, measurements, meta, _config) do
    Logger.debug("[MYCOBOT] event: #{inspect(event)}")
    Logger.debug("[MYCOBOT] measurements: #{inspect(measurements)}")
    Logger.debug("[MYCOBOT] meta: #{inspect(meta)}")
  end
end
