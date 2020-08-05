defmodule Scenic.Driver.Nerves.Input do
  @moduledoc """
  # scenic_driver_nerves_input

  The main driver for receiving any input on Nerves devices.

  So far only tested on Raspberry Pi 3 devices. In other words, it is still early
  days for this driver. There will probably be changes in the future. Especially
  regarding multi-touch.

  For now, the events coming to a scene via the touch driver look like the
  same cursor oriented events that come from glfw with a mouse.

  ## Installation

  In your Nerves applications dependencies include the following line

  ###    ...
  ###    {:scenic_driver_nerves_touch, , "~> 0.9"}
  ###    ...

  You do not need to include it in the "host" mix target deps. There you should be
  using the glfw driver and that will take care of the touch input for you.

  ## Configuration

  Configure the touch driver the same way you configure other drivers. Add it
  to the driver list in your ViewPort's config.exs file.

      config :sample, :viewport, %{
            size: {800, 480},
            default_scene: {Sample.Scene.Simple, nil},
            drivers: [
              %{
                module: Scenic.Driver.Nerves.Rpi,
              },
              %{
                module: Scenic.Driver.Nerves.Input,
                opts: [
                  device: "Mouse",
                  #calibration: {{1,0,0},{0,1,0}},
                ],
              }
            ]
          }

  ## Device Name

  __This is important__

  You need to supply the name of the OS driver you are getting the touch information from.
  You don't need to supply the entire string, but what you supply must be in the
  actual device name.

  When you use the sample scene set up by scenic.new.nerves, it will display the
  available device names. Otherwise, use the hex package [input_event](https://hex.pm/packages/input_event) to enumerate them.

  Note that some drivers take a short time to come online. (I'm looking at you FT5406).
  Don't be surprised if touch doesn't work for a second or two after the rest of the
  UI starts to work. Other drivers initialize themselves faster.

  The device name is this part of the configuration

      device: "FT5406 memory based driver",

  ## Calibration

  Calibration maps the resolution/coordinates of the touch screen to the
  coordinates and scale of the display. On the official Raspberry Pi
  7" touch screen, then are the same, so the mapping is easy (1.0).

  However, with other displays (I have a Dell touchscreen I've tested with),
  that is not the case and you need to provide a proper mapping. The values
  are sufficient to support some rotation and out-of-alignment issues in
  the future, but I haven't written a calibration scene yet to provide
  those values in an easy/automatic way.

  """

  use Scenic.ViewPort.Driver
  alias Scenic.ViewPort
  # alias :mnesia, as: Mnesia

  require Logger

  # import IEx

  # @port  '/scenic_driver_rpi_touch'

  @init_retry_ms 400

  # ============================================================================
  # client callable api

  @doc """
  Retrieve stats about the driver
  """
  def query_stats(pid), do: GenServer.call(pid, :query_stats)

  # ============================================================================
  # startup

  def init(viewport, {_, _} = screen_size, config) do
    Logger.debug("Scenic.Driver.Nerves.Input->config:#{inspect config}")
    device =
      case config[:device] do
        device when is_bitstring(device) ->
          Process.send(self(), {:init_driver, device}, [])
          device

        _ ->
          msg =
            "Scenic.Driver.Nerves.Input requires a device option to start up\r\n" <>
              "The named device must reference a valid driver on your target system\r\n" <>
              "The following works with a raspberry pi with the standard 7 inch touch screen...\r\n" <>
              "%{\r\n" <>
              "  module: Scenic.Driver.Nerves.Touch,\r\n" <>
              "  opts: [device: \"FT5406 memory based driver\"],\r\n" <> "}"

          Logger.error(msg)
          nil
      end
    

    state = %{
      device: device,
      event_path: nil,
      event_pid: nil,
      viewport: viewport,
      #mouse_pointer: mouse_pid,
      #cur_pos: {0,0},
      mouse_x: 0,
      mouse_y: 0,
      mouse_event: nil,
      config: config,
      screen_size: screen_size
    }

    {:ok, state}
  end

  # ============================================================================
  def handle_call(_msg, _from, state), do: {:reply, :e_no_impl, state}

  # ============================================================================

  # --------------------------------------------------------
  # We are starting up.
  # Enumerate the events/device pairs and look for the requested device.
  # If it is NOT found, log a warning and try again later (it might not be loaded yet)
  # If it is found, connect and start working for real
  def handle_info({:init_driver, requested_device}, state) do
    Logger.debug("requested_device:#{inspect requested_device}")
    InputEvent.enumerate()
    |> Enum.find_value(fn
      # input_event 0.3.1
      {event, device_name} when is_binary(device_name) ->
        if device_name =~ requested_device do
          event
        else
          nil
        end

      # input_event >= 0.4.0
      {event, info} when is_map(info) ->
        if info.name =~ requested_device do
          event
        else
          nil
        end
    end)
    |> case do
      nil ->
        Logger.warn("Device not found: #{inspect(requested_device)}")
        # not found. Try again later
        Process.send_after(self(), {:init_driver, requested_device}, @init_retry_ms)
        {:noreply, state}

      event ->
        # start listening for input messages on the event file
        {:ok, pid} = InputEvent.start_link(event)
        Logger.debug("InputEvent.start_link(#{inspect event})")
        # start post-init calibration check
        # Process.send(self(), :post_init, [])
        # Process.send(self(), {:post_init, 20}, [])

        {:noreply, %{state | event_pid: pid, event_path: event}}
    end
  end

  # --------------------------------------------------------
  # We have connected to the touch driver. See if there is a stored
  # calibration override
  # def handle_info( {:post_init, 0}, state ), do: {:noreply, state}
  # def handle_info( :post_init, %{
  # viewport:     vp,
  # config:       config,
  # calibration:  calibration,
  # screen_size: {width, height}
  # } = state ) do
  # if there ls a locally stored calibration record, use that instead of the
  # default one that was passed into config. Measured beats default

  # Find the static monitor. Try again later if there isn't one.
  #     {:ok, %{drivers: drivers}} = ViewPort.query_status(vp)
  #     state = Enum.find(drivers, fn
  #       {_pid, %{type: "Static Monitor"}} -> true
  #       _ -> false
  #     end)
  #     |> case do
  #       nil ->
  #         # not found. Try again later
  # IO.puts "try again later"
  #         Process.send_after(self(), {:post_init, tries_left - 1}, @init_retry_ms)
  #         state

  #       %{width: width, height: height} ->
  # pry()
  #         Mnesia.start()
  #         Mnesia.dirty_read({:touch_calibration, {width,height}})
  #         |> case do
  #           [] -> state
  #           [{:touch_calibration, _, {{_,_,_},{_,_,_}} = calib}] ->
  #             Map.put(state, :calibration, calib)
  #           _ ->
  #             # don't understand the stored calibration. Do nothing.
  #             state
  #         end

  #       _ ->
  #         # unknown monitor format. ignore it.
  #         state
  #     end

  # pry()
  #     Mnesia.start()
  #     state = Mnesia.dirty_read({:touch_calibration, {width,height}})
  #     |> case do
  #       [] -> state
  #       [{:touch_calibration, _, {{_,_,_},{_,_,_}} = calib}] ->
  #         Map.put(state, :calibration, calib)
  #       _ ->
  #         # don't understand the stored calibration. Do nothing.
  #         state
  #     end
  # pry()
  #   {:noreply, state}
  # end

  # --------------------------------------------------------
  # first handling for the input events we care about
  def handle_info({:input_event, source, events}, %{event_path: event_path} = state)
      when source == event_path do

    state =
      Enum.reduce(events, state, fn ev, s ->
        ev_rel(ev, s)
        # |> simulate_mouse(ev)
      end)
      |> send_mouse()

    #Logger.debug(":input_event ev: #{inspect events}-> #{inspect(state[:cur_pos])}")
    {:noreply, state}
  end

  # --------------------------------------------------------
  def handle_info(msg, state) do
    #IO.puts("Unhandled info. msg: #{inspect(msg)}")
    Logger.debug("Unhandled info. msg: #{inspect(msg)}")
    {:noreply, state}
  end


  # if other ev types need to be handled, add them here

  defp ev_rel({:ev_rel, :rel_x, rel_x}, state) do 
    state = ev_setpos({rel_x, 0}, state)
    %{state | mouse_event: :mouse_move}
  end
  defp ev_rel({:ev_rel, :rel_y, rel_y}, state) do
    state = ev_setpos({0, rel_y},state)
    %{state | mouse_event: :mouse_move}    
  end
  defp ev_rel({:ev_key, :btn_left, 1}, state) do
    state = %{state | mouse_event: :mouse_down}

    Logger.debug("send_mouse: #{inspect state}")

    state
  end
  defp ev_rel({:ev_key, :btn_left, 0}, state), do: %{state | mouse_event: :mouse_up}

  #defp ev_rel({:ev_key, :btn_right, _b}, state), do: state 

  defp ev_rel(_msg, state), do: state


  defp ev_setpos({rel_x, rel_y}, state) do
    %{mouse_x: x, mouse_y: y} = state
    {max_x, max_y} = state[:screen_size]
    #Logger.debug("pos: {#{x}, #{y}} ")
    state = %{state | mouse_x: limit_pos(x + rel_x, max_x), 
                      mouse_y: limit_pos(y + rel_y, max_y)
            }
  end

  defp limit_pos(pos, _max_p) when pos < 0, do: 0.0
  defp limit_pos(pos, max_p) when max_p < pos, do: max_p * 1.0
  defp limit_pos(pos, _max_p), do: pos * 1.0

  defp send_mouse(state)

  # send cursor_button press. no modifiers
  defp send_mouse(
         %{
           viewport: viewport,
           mouse_x: x,
           mouse_y: y,
           mouse_event: :mouse_down
         } = state
       )
       when is_number(x) and is_number(y) do
    # IO.puts "MOUSE press: #{inspect({x,y})}"
    pos = project_pos({x, y}, state)
    ViewPort.input(viewport, {:cursor_button, {:left, :press, 0, pos}})

    %{state | mouse_event: nil}
  end

  # send cursor_button release. no modifiers
  defp send_mouse(
          %{
            viewport: viewport, 
            mouse_x: x, 
            mouse_y: y, 
            mouse_event: :mouse_up} = state
       )
       when is_number(x) and is_number(y) do
    # IO.puts "MOUSE release: #{inspect({x,y})}"
    pos = project_pos({x, y}, state)
    ViewPort.input(viewport, {:cursor_button, {:left, :release, 0, pos}})
    %{state | mouse_x: nil, mouse_y: nil, mouse_event: nil}
  end

  # send cursor_pos. no modifiers
  defp send_mouse(
        %{
          viewport: viewport, 
          mouse_x: x, 
          mouse_y: y, 
          mouse_event: :mouse_move} = state
       )
       when is_number(x) and is_number(y) do
    # IO.puts "MOUSE move: #{inspect({x,y})}"
    pos = project_pos({x, y}, state)
    ViewPort.input(viewport, {:cursor_pos, pos})
    mouse_pid = :global.whereis_name(:mouse_pointer)
    send(mouse_pid, {:position, {x, y}})
    Logger.info("mouse pointer(#{inspect mouse_pid})-> {#{x}, #{y}}")

    %{state | mouse_event: nil}
  end

  # generic mouse_up catch-all. For some reason a x or y was never set, so
  # this is invalid and the mouse state should be cleared
  #defp send_mouse(%{mouse_event: :mouse_up} = state) do
  #  %{state | mouse_x: nil, mouse_y: nil, mouse_event: nil}
  #end

  # fall-through. do nothing
  defp send_mouse(state) do
    state
  end

  # --------------------------------------------------------
  # project the measured x value by the calibration data to get the screen x
  defp project_pos({x, y}, %{calibration: {{ax, bx, dx}, {ay, by, dy}}}) do
    {
      x * ax + y * bx + dx,
      x * ay + y * by + dy
    }
  end

  defp project_pos(pos, _), do: pos
end
