defmodule IodeviceTest do
  use ExUnit.Case
  doctest Iodevice

  test "greets the world" do
    assert Iodevice.hello() == :world
  end
end
