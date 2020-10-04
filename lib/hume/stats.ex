defmodule Hume.Stats do
  require Logger

  def handle_event([:hume, :sensor], measurements, _meta, _config) do
    Logger.info("[HUME] sensor data received: #{IO.inspect(measurements)}")
  end

  def handle_event([:hume, :power], measurements, meta, _config) do
    Logger.info("[HUME] power cycle received: #{IO.inspect(measurements)} meta: #{IO.inspect(meta)}")
  end
end
