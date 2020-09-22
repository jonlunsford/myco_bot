defmodule Hume.OLED do
  require Logger
  use OLED.Display, app: :hume

  def write(text, x, y, font) do
    clear(:off)
    Logger.debug("[HUME] Clearing OLED")
    display()
    Chisel.Renderer.draw_text(text, x, y, font, &draw_pixel/2)
    Logger.debug("[HUME] Rendering OLED")
    display()
  end

  def draw_pixel(x, y) do
    put_pixel(x, y, [state: :on, mode: :xor])
  end
end
