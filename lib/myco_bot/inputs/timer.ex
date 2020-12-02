defmodule MycoBot.Inputs.Timer do
  @moduledoc """
  Implements a timer calling itself per config passed in
  """

  defstruct description: "Generic, digital, timer"

  def init(args) do
    MycoBot.Telemetry.start_poller(
      measurements: [{__MODULE__, :call, [args]}],
      period: timing(args),
      name: args.name
    )
  end

  def call(args) do
    case args.output_type do
      :gpio -> MycoBot.GPIO.toggle(args.output_pin)
      _ -> telemetry(:error, %{}, %{error: "Unhandled output type: #{args.output_type}"})
    end
  end

  defp timing(args) do
    case args.interval do
      :minute -> :timer.minutes(args.length)
      :hour -> :timer.hours(args.length)
      :second -> :timer.seconds(args.length)
    end
  end

  defp telemetry(event, metrics, meta \\ %{}) do
    meta = Map.put(meta, :module, __MODULE__)
    :telemetry.execute([:myco_bot, :timer, event], metrics, meta)
  end
end
