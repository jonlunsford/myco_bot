defmodule MycoBot.Sensor do
  require Logger

  use GenServer

  alias Circuits.I2C

  @default_addr 0x40 # Address where bits are written/read
  @rh_hold_cmd <<0xE5>>
  #@rh_no_hold_cmd <<0xF5>>
  @temp_hold_cmd <<0xE3>>
  #@temp_no_hold_cmd <<0xF3>>
  #@read_temp_cmd <<0xE0>> # Read temp from last RH measurement
  @reset <<0xFE>>
  #@write_cmd <<0xE6>> # write RH/T user register 1
  #@read_cmd <<0xE7>> # read RH/T user register 1
  #@write_heater_cmd <<0x51>> # Write heater control register
  #@read_heater_cmd <<0x11>> # Read heater control register
  #@heater_reg_bit_cmd <<0x02>> # Control register bit
  #@id1_bit 0xFA0F # Read Electronic ID 1st byte
  #@id2_bit 0xFCC9 # Read Electronic ID 2nd byte
  #@rirmware_vsn_cmd <<0x84B8>>
  #@rev_1_cmd <<0xff>>
  #@rev_2_cmd <<0x20>>

  def start_link(arg) do
    Logger.debug("[MYCO] Starting Sensor Server")

    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_) do
    state = %{
      temp: nil,
      rh: nil,
      ref: nil,
      error: nil
    }

    case I2C.open("i2c-1") do
      {:ok, ref} ->
        Logger.debug("[MYCO] I2C Sensor Found, resetting it")
        I2C.write(ref, @default_addr, @reset)

        {:ok, %{state | ref: ref}}
      {:error, reason} ->
        Logger.warn("[MYCO] I2C Sensor Not Found: #{reason}")

        :telemetry.execute(
          [:myco_bot, :sensor],
          %{error: reason},
          %{extra: "I2C sensor not found. Is everything plugged in?"}
        )

        {:ok, state}
    end
  end

  def read_rh() do
    GenServer.call(__MODULE__, :read_rh)
  end

  def read_temp() do
    GenServer.call(__MODULE__, :read_temp)
  end

  @impl true
  def handle_call(:read_temp, _from, state) do
    {temp, state} = do_read_temp(state)
    {:reply, temp, state}
  end

  @impl true
  def handle_call(:read_rh, _from, state) do
    {rh, state} = do_read_rh(state)
    {:reply, rh, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  defp do_read_temp(state) do
    case I2C.write_read(state.ref, @default_addr, @temp_hold_cmd, 2) do
      {:ok, bits} ->
        Logger.debug("[MYCO] CONVERTING: #{bits}")
        temp = convert_temp(bits)
        Logger.debug("[MYCO] FAHRENHEIT: #{temp}")
        {temp, %{state | temp: temp}}
      {:error, reason} ->
        Logger.warn("ERROR: #{reason}")
        {:error, %{state | error: reason}}
    end
  end

  defp convert_temp(bits) when is_bitstring(bits) do
    reading = :binary.decode_unsigned(bits)
    Logger.debug("[MYCO] READING: #{reading}")
    value = (reading * 175.72) / 65536 - 46.85
    Logger.debug("[MYCO] CELSIUS: #{value}")

    value
    |> celcius_to_f
    |> Float.round
  end
  defp convert_temp(_), do: 0.0

  defp celcius_to_f(temp) when is_float(temp) do
    temp / 5 * 9 + 32
  end
  defp celcius_to_f(_), do: 0.0

  defp do_read_rh(state) do
    case I2C.write_read(state.ref, @default_addr, @rh_hold_cmd, 2) do
      {:ok, bits} ->
        Logger.debug("[MYCO] CONVERTING: #{bits}")
        rh = convert_rh(bits)
        Logger.debug("[MYCO] HUMIDITY: #{rh}")
        {rh, %{state | rh: rh}}
      {:error, reason} ->
        Logger.warn("ERROR: #{reason}")
        {:error, %{state | error: reason}}
    end
  end

  defp convert_rh(bits) when is_bitstring(bits) do
    reading = :binary.decode_unsigned(bits)
    Logger.debug("[MYCO] READING: #{reading}")
    value = (reading * 125) / 65536 - 6

    value
    |> Float.round
  end
end
