defmodule MycoBot.MixProject do
  use Mix.Project

  @app :myco_bot
  @version "0.1.0"
  @all_targets [:rpi2, :rpi0]

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.10",
      archives: [nerves_bootstrap: "~> 1.8"],
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      aliases: [loadconfig: [&bootstrap/1]],
      deps: deps(),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host]
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {MycoBot.Application, []},
      extra_applications: [:logger, :runtime_tools, :inets]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:nerves, "~> 1.6.0", runtime: false},
      {:shoehorn, "~> 0.6"},
      {:ring_logger, "~> 0.6"},
      {:toolshed, "~> 0.2"},

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.6", targets: @all_targets},
      {:nerves_pack, "~> 0.2", targets: @all_targets},
      {:circuits_i2c, "~> 0.1"},
      {:circuits_gpio, "~> 0.4"},
      {:telemetry, "~> 0.4.2"},
      # Display deps
      {:oled, "~> 0.3.0"},
      {:chisel, "~> 0.2.0"},
      # Dependencies for specific targets
      {:nerves_system_rpi2, "~> 1.12", runtime: false, targets: :rpi2},
      {:nerves_system_rpi0, "~> 1.12", runtime: false, targets: :rpi0}
    ]
  end

  def release do
    [
      overwrite: true,
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod
    ]
  end
end
