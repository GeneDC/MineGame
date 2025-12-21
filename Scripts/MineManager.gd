extends Node

var orePool: OrePool = null

var grid_item_parent: Node3D = null
var grid_size := Vector3i(10, 10, 10)
var item_to_place: PackedScene = preload("res://Prefabs/Conveyor.tscn")
var raycast: RayCast3D = null
var preview_ghost: Node3D = null
var ghost_material_placable: Material = preload("res://Materials/GhostItemBlueMaterial.tres")
var ghost_material_nonplacable: Material = preload("res://Materials/GhostItemRedMaterial.tres")
var place_item_coordinate: Vector3i = Vector3i.ZERO
var grid_items: Array[GridItem] = []


func _ready() -> void:
	GameImGui.RegisterMainMenuWindow("Debug", "Mine Manager", _ImguiWindow)

	orePool = OrePool.new()
	orePool.name = "Ore Pool"
	add_child(orePool)

	preview_ghost = item_to_place.instantiate() as Node3D
	preview_ghost.name = "Preview Item Ghost"
	_prepare_ghost_recursive(preview_ghost, ghost_material_placable)
	add_child(preview_ghost)

	grid_item_parent = Node3D.new()
	grid_item_parent.name = "Grid Items"
	add_child(grid_item_parent)

	grid_items.resize(grid_size.x * grid_size.y * grid_size.z)
	
	raycast = get_tree().current_scene.get_node("Camera3D/RayCast3D")
	assert(raycast != null)

func _process(_delta: float) -> void:
	if not raycast.is_colliding():
		preview_ghost.visible = false
		return

	var collision_point := raycast.get_collision_point()
	var collision_normal := raycast.get_collision_normal()

	# Offset the point slightly along the normal to stay on top of the surface
	var target_pos := collision_point + (collision_normal * 0.5)
	place_item_coordinate = target_pos.snapped(Vector3.ONE)
	
	if not _is_valid_coordinate(place_item_coordinate):
		# make ghost red
		return

	preview_ghost.global_position = place_item_coordinate
	preview_ghost.visible = true

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
	#if Input.is_action_just_pressed("place_object"):
		_place_item(preview_ghost.global_position)


func _place_item(coordinate: Vector3i) -> void:
	if not _is_valid_coordinate(place_item_coordinate):
		push_error("trying to place item outside of the grid!")
		return
	
	var grid_item := item_to_place.instantiate() as GridItem
	if not grid_item:
		push_error("Failed to instantiate grid item.")
		return

	grid_item_parent.add_child(grid_item)
	grid_item.global_position = Vector3(coordinate)
	grid_items[coordinate.x + coordinate.y * coordinate.y + coordinate.z * coordinate.z * coordinate.z] = grid_item

func _is_valid_coordinate(coordinate: Vector3i) -> bool:
	return coordinate.x < grid_size.x && coordinate.y < grid_size.y && coordinate.z < grid_size.z

## Returns true if there is no item at this coordinate
func _is_coordinate_free(coordinate: Vector3i) -> bool:
	return grid_items[coordinate.x + coordinate.y * coordinate.y + coordinate.z * coordinate.z * coordinate.z] == null

func _prepare_ghost_recursive(node: Node, ghost_material: Material) -> void:
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
			mesh_instance.set_surface_override_material(i, ghost_material)
		
	for child in node.get_children():
		_prepare_ghost_recursive(child, ghost_material)

func _ImguiWindow() -> void:
	ImGui.Text("Mine Manager...")
	
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
