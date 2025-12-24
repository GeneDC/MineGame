extends GridItem
class_name GridItem_Conveyor

@export var speed: float = 0.2

@onready var belt: ConveyorBelt = $Belt
@onready var belt_mesh: MeshInstance3D = $Conveyor/ConveyorBelt

@onready var left_side_nodes: Array[Node3D] = [$Conveyor/ConveyorLeftSide, $Sides/Left]
@onready var right_side_nodes: Array[Node3D] = [$Conveyor/ConveyorRightSide, $Sides/Right]


func _ready() -> void:
	belt.update_conveyor_velocity(speed)
	
	var material := belt_mesh.get_active_material(0)
	# This will modify all uses of this material
	# for different speeds, use different materials
	# TODO: use an approach such that this is only done once
	if material is ShaderMaterial:
		var shader_material := material as ShaderMaterial
		shader_material.set_shader_parameter("scroll_speed_y", speed)

func grid_update(forward: GridItem, right: GridItem,
					back: GridItem, 	left: GridItem,
					up: GridItem, down: GridItem) -> void:
	super(forward, right, back, left, up, down)
	#TODO: the passed in grid items are cardinally positioned. We would need to calculate what "left" is based on our rotation
	# perhaps grid items should know their facing direction?
	if left is GridItem_Conveyor:
		if direction_right(left.direction) == direction:
			HideLeftSide()
		
	if right is GridItem_Conveyor:
		if direction_left(right.direction) == direction:
			HideRightSide()

func HideLeftSide() -> void:
	for node in left_side_nodes:
		_SetNodeEnabledRecursive(node, false)
		
func HideRightSide() -> void:
	for node in right_side_nodes:
		_SetNodeEnabledRecursive(node, false)
	
func _SetNodeEnabledRecursive(node: Node, enabled: bool) -> void:
	node.set_process(enabled)
	node.set_physics_process(enabled)

	# Disable rendering
	if node is Node3D:
		var node3d := node as Node3D
		node3d.visible = enabled
		
	# Disable Collisions
	if node is CollisionShape3D:
		var collision_shape := node as CollisionShape3D
		collision_shape.disabled = not enabled
		
	
	for child in node.get_children():
		_SetNodeEnabledRecursive(child, enabled)
