defmodule MycoBot.Application do
  require Logger
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    Logger.info("[MYCO]: Starting Application")
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MycoBot.Supervisor]
    children =
      [
        {MycoBot.Sensor, []},
        #MycoBot.OLED,
        #{MycoBot.Display, %{font: "Chroma48Medium-8.bdf"}},
        {MycoBot.Power, []},
        {MycoBot, []}
      ] ++ children(target())

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
    ]
  end

  def target() do
    Application.get_env(:myco_bot, :target)
  end
end
