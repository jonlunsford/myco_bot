defmodule MycoBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MycoBot.Supervisor]

    children =
      [
        {Registry, keys: :unique, name: MycoBot.Pollers},
        {Registry, keys: :unique, name: MycoBot.Pins},
        {MycoBot.Telemetry, []},
        {MycoBot.Relay, []},
        {MycoBot.Environment, []},
        {MycoBot, myco_bot_config()}
      ] ++ children(target())

    MycoBot.Instrumenter.setup()

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: MycoBot.Worker.start_link(arg)
      # {MycoBot.Worker, arg},
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      # Starts a worker by calling: MycoBot.Worker.start_link(arg)
      # {MycoBot.Worker, arg},
      %{
        id: TelemetryInfluxDB,
        start:
          {TelemetryInfluxDB, :start_link,
           [[
             events: [
               %{name: [:myco_bot, :sht30, :read]},
               %{name: [:myco_bot, :influx_test]}
             ],
             version: :v2,
             protocol: :http,
             host: "https://us-west-2-1.aws.cloud2.influxdata.com",
             port: 443,
             bucket: "myco_bot",
             org: "jon@capturethecastle.net",
             token: Application.get_env(:myco_bot, :influx_data_key)
           ]]}
      }
    ]
  end

  def myco_bot_config do
    %{
      inputs: [
        # {MycoBot.Inputs.SI7021, [bus_name: "i2c-1", polling_period: 30]},
        # {MycoBot.Inputs.DHT22, %{pin_number: 4, polling_period: 30}},
        # {MycoBot.Inputs.VEML7700,
        # %{bus_name: "i2c-1", gain: 1, integration_time: 200, polling_period: 30}},
        {MycoBot.Inputs.SHT30, %{bus_name: "i2c-1", polling_period: 15}},
        {MycoBot.Inputs.Timer,
         %{
           name: :light_timer,
           output_type: :gpio,
           output_pin: 13,
           interval: :hour,
           length: 12
         }}
      ],
      outputs: [
        %{
          type: :gpio,
          pin: 26,
          direction: :output,
          value: 1,
          polarity: :reverse,
          description: "Fogger"
        },
        %{
          type: :gpio,
          pin: 5,
          direction: :output,
          value: 0,
          polarity: :reverse,
          description: "Air Intake"
        },
        %{
          type: :gpio,
          pin: 0,
          direction: :output,
          value: 1,
          polarity: :reverse,
          description: "Exhaust Fan"
        },
        %{
          type: :gpio,
          pin: 13,
          direction: :output,
          value: 0,
          polarity: :reverse,
          description: "Lights"
        },
        %{
          type: :gpio,
          pin: 11,
          direction: :output,
          value: 1,
          polarity: :reverse,
          description: "Circulation Fan 1"
        },
        %{
          type: :gpio,
          pin: 9,
          direction: :output,
          value: 1,
          polarity: :reverse,
          description: "Circulation Fan 2"
        },
        %{
          type: :gpio,
          pin: 6,
          direction: :output,
          value: 1,
          polarity: :reverse,
          description: "Misc 1"
        }
      ]
    }
  end

  def target() do
    Application.get_env(:myco_bot, :target)
  end
end
