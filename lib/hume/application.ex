defmodule Hume.Application do
  require Logger
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    Logger.info("[HUME]: Starting Application")
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hume.Supervisor]
    children =
      [
        {Hume.Sensor, []},
        #Hume.OLED,
        #{Hume.Display, %{font: "Chroma48Medium-8.bdf"}},
        {Hume.Power, []},
        {Hume, []}
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: Hume.Worker.start_link(arg)
      # {Hume.Worker, arg},
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      # Starts a worker by calling: Hume.Worker.start_link(arg)
      # {Hume.Worker, arg},
    ]
  end

  def target() do
    Application.get_env(:hume, :target)
  end
end
