defmodule MycoBotTest do
  use ExUnit.Case
  doctest MycoBot

  test "greets the world" do
    assert MycoBot.hello() == :world
  end
end
