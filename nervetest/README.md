Scenic Evaluation test
-----



nav.graph:
%Scenic.Graph{
add_to: 0, animations: [], ids: %{_root_: [0], nav: [3]}, next_uid: 5, primitives: %{
0 => %{__struct__: Scenic.Primitive, data: [1, 2, 3, 4], 
   module: Scenic.Primitive.Group, parent_uid: -1, styles: %{font: :roboto, font_size: 20, theme: :dark}}, 
1 => %{__struct__: Scenic.Primitive, data: {1920, 60}, 
   module: Scenic.Primitive.Rectangle, parent_uid: 0, styles: %{fill: {48, 48, 48}}}, 
2 => %{__struct__: Scenic.Primitive, data: "Scene:", 
   module: Scenic.Primitive.Text, parent_uid: 0, styles: %{align: :right}, transforms: %{translate: {14, 35}}}, 
3 => %{__struct__: Scenic.Primitive, data: {Scenic.Component.Input.Dropdown, {[{"Sensor", Nervetest.Scene.Sensor}, {"Sensor (spec)", Nervetest.Scene.SensorSpec}, {"Primitives", Nervetest.Scene.Primitives}, {"Components", Nervetest.Scene.Components}, {"Transforms", Nervetest.Scene.Transforms}], Nervetest.Scene.Sensor}}, id: :nav, 
   module: Scenic.Primitive.SceneRef, parent_uid: 0, transforms: %{translate: {70, 15}}}, 
4 => %{__struct__: Scenic.Primitive, data: {Scenic.Clock.Digital, nil},  
   module: Scenic.Primitive.SceneRef, parent_uid: 0, styles: %{text_align: :right}, transforms: %{translate: {1900, 35}}}}}


mouse.graph:%Scenic.Graph{
add_to: 0, animations: [], ids: %{_root_: [0], cursor: [1]}, next_uid: 2, primitives: %{
0 => %{__struct__: Scenic.Primitive, data: [1], 
   module: Scenic.Primitive.Group, parent_uid: -1, styles: %{font: :roboto, font_size: 24}}, 
1 => %Scenic.Primitive{data: {80, 80}, id: :cursor, 
   module: Scenic.Primitive.Rectangle, parent_uid: 0, styles: %{fill: {:image, {"GfmYFMCXPDFjgU4CmthmLDMKz_0", 0}}}, transforms: %{translate: {200, 200}}}}}


splash.graph:%Scenic.Graph{
add_to: 0, animations: [], ids: %{_root_: [0], parrot: [1]}, next_uid: 2, primitives: %{
0 => %{__struct__: Scenic.Primitive, data: [1], 
   module: Scenic.Primitive.Group, parent_uid: -1, styles: %{font: :roboto, font_size: 24}}, 
1 => %Scenic.Primitive{data: {410, 234}, id: :parrot, 
   module: Scenic.Primitive.Rectangle, parent_uid: 0, styles: %{fill: {:image, {"4FEFB1_O8oikG4L7ec0qjV2-VS8", 0}}}, transforms: %{translate: {755.0, 423.0}}}}}