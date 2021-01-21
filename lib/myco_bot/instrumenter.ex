defmodule MycoBot.Instrumenter do
  require Logger

  def setup do
    events = [
      # [:myco_bot, :started],

      # [:myco_bot, :si7021, :read],
      # [:myco_bot, :si7021, :error],

      [:myco_bot, :sht30, :read],
      # [:myco_bot, :sht30, :error],

      # [:myco_bot, :veml7700, :read],
      # [:myco_bot, :veml7700, :error],

      [:myco_bot, :gpio, :error],
      # [:myco_bot, :gpio, :opened],
      # [:myco_bot, :gpio, :up],
      # [:myco_bot, :gpio, :down],
      # [:myco_bot, :gpio, :sync],

      [:myco_bot_ui, :device, :refresh],
      [:myco_bot_ui, :device, :change],
      [:myco_bot_ui, :dashboard, :mounted]
    ]

    Logger.debug("[MYCOBOT] Setting up instrumentation: #{inspect(events)}")

    :telemetry.attach_many(
      "mycobot-instrumenter",
      events,
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event([:myco_bot, :sht30, :read], measurements, _meta, _config) do
    if measurements.humidity >= 96 do
      MycoBot.GPIO.down(26) # Fog
      MycoBot.GPIO.up(0) # Exhaust
      MycoBot.GPIO.up(11) # Circ fan 1
      MycoBot.GPIO.up(9) # Circ fan 2
    else
      MycoBot.GPIO.up(26)
      MycoBot.GPIO.down(0) # Exhaust
      MycoBot.GPIO.down(11) # Circ fan 1
      MycoBot.GPIO.down(9) # Circ fan 2
    end
  end

  def handle_event([:myco_bot_ui, :device, :refresh], _measurements, _meta, _config) do
    Logger.debug("[MYCOBOT] Received request to refresh devices")
    MycoBot.Relay.report_states()
  end

  def handle_event([:myco_bot_ui, :dashboard, :mounted], _measurements, _meta, _config) do
    Logger.debug("[MYCOBOT] Received dashboard mount, reporting relay states")
    MycoBot.Relay.report_states()
  end

  def handle_event([:myco_bot_ui, :device, :change], _measurements, meta, _config) do
    Logger.debug("[MYCOBOT] [:myco_bot_ui, :device, :change]: #{inspect(meta)}")

    if meta.value == :up,
      do: MycoBot.GPIO.up(meta.pin),
      else: MycoBot.GPIO.down(meta.pin)
  end

  def handle_event(event, measurements, meta, _config) do
    Logger.debug("[MYCOBOT] event: #{inspect(event)}")
    Logger.debug("[MYCOBOT] measurements: #{inspect(measurements)}")
    Logger.debug("[MYCOBOT] meta: #{inspect(meta)}")
  end
end
