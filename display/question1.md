Could anyone please help me to solve the problem of camera image?
I try to draw the image which is taken from Picam as Jpg format.
```
  def init(current_scene, opts) do
    ---
    pid = Swarm.whereis_name(:picture)
    data =  get_picture(pid)
    Scenic.Cache.Dynamic.Texture.put_new("camera_frame", {:rgba, 400, 400, data, []})
    position = {100,100}
    graph = Graph.build()
              |> rect( {400, 400}, id: :camera, fill: {:dynamic, "camera_frame"})
              |> Graph.modify( :camera, &update_opts(&1, translate: position))
    {:ok, graph, push: graph}
  end

  # camera module send this module {:put, data}
  def handle_info({:put, data}, graph) do
    Scenic.Cache.Dynamic.Texture.put("camera_frame", {:rgba, 400, 400, data, []})
    graph =
      Graph.modify( graph, :camera, &update_opts(&1, fill: {:dynamic, "camera_frame"}))
    {:noreply, graph, push: graph}
  end
```
The camera data doesn't show up.
To my investigation, Camera file is Jpeg, but it should be raw pixels data as [Documentation](https://github.com/boydm/scenic/blob/master/lib/scenic/cache/dynamic/texture.ex#L28) said. And raw pixels data is supposed to be RGB888 format. I found raw pixels is different from BMP, and RGB888 file I manually made on a Web is OK to show up although size is wrong and I have to change Scenic code.

How can we draw camera image on Scenic?

Thanks.

