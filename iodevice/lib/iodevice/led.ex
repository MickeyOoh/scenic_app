defmodule Iodevice.Led do
  require Logger

  alias Circuits.GPIO

  @led_pin Application.get_env(:iodevice, :led_pin, 18)

  def switch_power() do
    GPIO.write(output_gpio(), 1 - GPIO.read(output_gpio()))
    |> broadcast(:power_switched)
  end

  def state do
    case GPIO.read(output_gpio()) do
      0 -> "off"
      1 -> "on"
    end
  end

  def subscribe do
    Phoenix.PubSub.subscribe(BirdAppUi.PubSub, "power")
  end

  defp output_gpio do
    {:ok, output_gpio} = GPIO.open(@led_pin, :output)
    output_gpio
  end

  defp broadcast(:ok, event) do
    Phoenix.PubSub.broadcast(BirdAppUi.PubSub, "power", {event, state()})
    {:ok, state()}
  end
end
