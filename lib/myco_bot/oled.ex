defmodule MycoBot.OLED do
  require Logger
  use OLED.Display, app: :myco_bot

  def write(text, x, y, font) do
    clear(:off)
    Logger.debug("[MYCO] Clearing OLED")
    display()
    Chisel.Renderer.draw_text(text, x, y, font, &draw_pixel/2)
    Logger.debug("[MYCO] Rendering OLED")
    display()
  end

  def draw_pixel(x, y) do
    put_pixel(x, y, [state: :on, mode: :xor])
  end
end
