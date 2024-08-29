defmodule MazesTest do
  use ExUnit.Case
  doctest Mazes

  test "greets the world" do
    assert Mazes.hello() == :world
  end
end
