# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

config :myco_bot,
  target: Mix.target(),
  influx_data_key: System.get_env("INFLUX_DATA_KEY")


# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

# config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"
config :nerves, :erlinit,
  ctty: "ttyAMA0",
  run_on_exit: "/bin/bash"

# Set the SOURCE_DATE_EPOCH date for reproducible builds.
# See https://reproducible-builds.org/docs/source-date-epoch/ for more information

config :nerves, source_date_epoch: "1591076337"

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.

config :logger, backends: [RingLogger]

import_config "../../myco_bot_ui/config/config.exs"

config :myco_bot_ui, MycoBotUiWeb.Endpoint,
  # Nerves root filesystem is read-only, so disable the code reloader
  code_reloader: false,
  http: [port: 80],
  # Use compile-time Mix config instead of runtime environment variables
  load_from_system_env: false,
  # Start the server since we're running in a release instead of through `mix`
  server: true,
  url: [host: "nerves.local", port: 80],
  render_errors: [view: MycoBotUiWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: MycoBotUi.PubSub,
  live_view: [signing_salt: "Fj2tZT4oGpy4WAER"],
  check_origin: ["http://nerves.local", "http://192.168.1.26"]

if Mix.target() != :host do
  import_config "target.exs"
end
