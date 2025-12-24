extends Node3D
class_name FactoryGrid

var grid_size := Vector3i(20, 10, 20)
var grid_item_scenes: Array[PackedScene] = [preload("res://Prefabs/GridItems/Conveyor.tscn")]
var item_to_place: PackedScene = preload("res://Prefabs/GridItems/Conveyor.tscn")
var raycast: RayCast3D = null
var preview_ghost: Node3D = null
var item_index: int = -2
var ghost_material_placable: Material = preload("res://Materials/GhostItemBlueMaterial.tres")
var ghost_material_nonplacable: Material = preload("res://Materials/GhostItemRedMaterial.tres")
var place_item_coordinate: Vector3i = Vector3i.ZERO
var grid_items: Array[GridItem] = []
var item_direction := GridItem.Direction.NORTH

func _ready() -> void:
	GameImGui.RegisterMainMenuWindow("Debug", "Factory Grid", _ImguiWindow)

	_select_item(-1)

	grid_items.resize(grid_size.x * grid_size.y * grid_size.z)
	
	raycast = get_tree().current_scene.get_node("Camera3D/RayCast3D")
	assert(raycast != null)

func _process(_delta: float) -> void:
	if not item_to_place:
		return;
	
	var target_pos := Vector3.ZERO
	if raycast.is_colliding():
		var collision_point := raycast.get_collision_point()
		var collision_normal := raycast.get_collision_normal()
		# Offset the point slightly along the normal to stay on top of the surface
		target_pos = collision_point + (collision_normal * 0.5)
	else:
		target_pos = raycast.to_global(raycast.target_position)

	# Round down as the grid origin is 0, 0, 0
	place_item_coordinate = Vector3i(floori(target_pos.x), floori(target_pos.y), floori(target_pos.z))
	
	var is_placable := (_is_valid_coordinate(place_item_coordinate) and 
						_is_coordinate_free(place_item_coordinate))
	if is_placable:
		_override_material_recursive(preview_ghost, ghost_material_placable)
	else:
		_override_material_recursive(preview_ghost, ghost_material_nonplacable)

	preview_ghost.global_position = Vector3(place_item_coordinate) + Vector3(0.5, 0.0, 0.5)
	preview_ghost.rotation.y = deg_to_rad(item_direction * -90)
	preview_ghost.visible = true

	if is_placable && Input.is_action_just_pressed("place_item"):
		_place_item(preview_ghost.global_position)
	
	if Input.is_action_just_pressed("rotate_item"):
		item_direction = GridItem.direction_right(item_direction)

func _select_item(new_item_index: int) -> void:
	if new_item_index != item_index:
		item_index = new_item_index
		
		item_to_place = null
		
		if preview_ghost:
			preview_ghost.queue_free()
			preview_ghost = null
		
		if item_index < 0:
			return
		
		item_to_place = grid_item_scenes[item_index]
		
		preview_ghost = item_to_place.instantiate() as Node3D
		preview_ghost.name = "Preview Item Ghost"
		_prepare_ghost_recursive(preview_ghost, ghost_material_placable)
		add_child(preview_ghost)

func _place_item(coordinate: Vector3i) -> void:
	if not _is_valid_coordinate(place_item_coordinate):
		push_error("trying to place item outside of the grid!")
		return
	
	var grid_item := item_to_place.instantiate() as GridItem
	if not grid_item:
		push_error("Failed to instantiate grid item.")
		return

	grid_item.rotation.y = deg_to_rad(item_direction * -90)
	grid_item.direction = item_direction
	
	add_child(grid_item)
	grid_item.global_position = Vector3(coordinate) + Vector3(0.5, 0.0, 0.5)
	grid_item.coodinate = coordinate
	grid_items[coordinate.x + coordinate.y * grid_size.x + coordinate.z * grid_size.x * grid_size.y] = grid_item

	_send_grid_update(coordinate)
	_send_grid_update(coordinate + Vector3i.FORWARD)
	_send_grid_update(coordinate + Vector3i.BACK)
	_send_grid_update(coordinate + Vector3i.LEFT)
	_send_grid_update(coordinate + Vector3i.RIGHT)
	_send_grid_update(coordinate + Vector3i.UP)
	_send_grid_update(coordinate + Vector3i.DOWN)

func _send_grid_update(coordinate: Vector3i) -> void:
	var grid_item := try_get_grid_item(coordinate)
	if not grid_item:
		return
	
	var grid_item_forward := try_get_grid_item(coordinate + Vector3i.FORWARD)
	var grid_item_back := try_get_grid_item(coordinate + Vector3i.BACK)
	var grid_item_left := try_get_grid_item(coordinate + Vector3i.LEFT)
	var grid_item_right := try_get_grid_item(coordinate + Vector3i.RIGHT)
	var grid_item_up := try_get_grid_item(coordinate + Vector3i.UP)
	var grid_item_down := try_get_grid_item(coordinate + Vector3i.DOWN)
	
	if grid_item.direction == GridItem.Direction.NORTH:
		grid_item.grid_update(grid_item_forward, grid_item_right, grid_item_back, grid_item_left, grid_item_up, grid_item_down)
	elif grid_item.direction == GridItem.Direction.EAST:
		grid_item.grid_update(grid_item_right, grid_item_back, grid_item_left, grid_item_forward, grid_item_up, grid_item_down)
	elif grid_item.direction == GridItem.Direction.SOUTH:
		grid_item.grid_update(grid_item_back, grid_item_left, grid_item_forward, grid_item_right, grid_item_up, grid_item_down)
	elif grid_item.direction == GridItem.Direction.WEST:
		grid_item.grid_update(grid_item_left, grid_item_forward, grid_item_right, grid_item_back, grid_item_up, grid_item_down)


func _is_valid_coordinate(coordinate: Vector3i) -> bool:
	return (coordinate.x < grid_size.x && coordinate.y < grid_size.y && coordinate.z < grid_size.z
			&& coordinate.x >= 0 && coordinate.y >= 0 && coordinate.z >= 0)

## Returns true if there is no item at this coordinate
func _is_coordinate_free(coordinate: Vector3i) -> bool:
	return grid_items[coordinate.x + coordinate.y * grid_size.x + coordinate.z * grid_size.x * grid_size.y] == null

func get_grid_item(coordinate: Vector3i) -> GridItem:
	return grid_items[coordinate.x + coordinate.y * grid_size.x + coordinate.z * grid_size.x * grid_size.y]

func try_get_grid_item(coordinate: Vector3i) -> GridItem:
	if _is_valid_coordinate(coordinate):
		return get_grid_item(coordinate)
	return null

func _prepare_ghost_recursive(node: Node, material: Material) -> void:
	# Disable Scripts & Processing
	node.set_process(false)
	node.set_physics_process(false)
	node.set_script(null)

	# Disable Collisions
	if node is CollisionObject3D:
		var collision_object := node as CollisionObject3D
		collision_object.collision_layer = 0
		collision_object.collision_mask = 0
	if node is CollisionShape3D:
		var collision_shape := node as CollisionShape3D
		collision_shape.disabled = true
		
	# Override all surface materials with ghost shader
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		for i in mesh_instance.mesh.get_surface_count():
			mesh_instance.set_surface_override_material(i, material)
		
	for child in node.get_children():
		_prepare_ghost_recursive(child, material)

func _override_material_recursive(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		for i in mesh_instance.mesh.get_surface_count():
			mesh_instance.set_surface_override_material(i, material)
	
	for child in node.get_children():
		_override_material_recursive(child, material)

# ImGui and Debug code:

var _imgui_show_grid := [false]

func _ImguiWindow() -> void:
	var items: Array[String] = ["none"]
	for scene in grid_item_scenes:
		items.append(scene.resource_path.get_file().get_basename())
	var current_index: Array[int] = [item_index + 1]
	if ImGui.ListBox("Item", current_index, items, items.size()):
		_select_item(current_index[0] - 1)
		
	ImGui.Checkbox("Show grid outline", _imgui_show_grid)
	if _imgui_show_grid[0]:
		_DebugShowGrid()
	
func _DebugShowGrid() -> void:
	var coordinate_a := Vector3.ZERO
	var coordinate_b := Vector3.ZERO
	for x in grid_size.x:
		coordinate_a.x = x
		coordinate_b.x = x + 1
		for y in grid_size.y:
			coordinate_a.y = y
			coordinate_b.y = y + 1
			for z in grid_size.z:
				coordinate_a.z = z
				coordinate_b.z = z + 1
				DebugDraw3D.draw_aabb_ab(coordinate_a, coordinate_b, Color.DARK_GREEN, 0)
