defmodule HumeTest do
  use ExUnit.Case
  doctest Hume

  test "greets the world" do
    assert Hume.hello() == :world
  end
end
