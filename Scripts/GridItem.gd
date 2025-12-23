extends Node3D
class_name GridItem

@export var speed: float = 0.2

@onready var belt: ConveyorBelt = $Belt
@onready var belt_mesh: MeshInstance3D = $Conveyor/ConveyorBelt

func _ready() -> void:
	belt.update_conveyor_velocity(speed)
	
	var material := belt_mesh.get_active_material(0)
	
	if material is ShaderMaterial:
		var shader_material := material as ShaderMaterial
		shader_material.set_shader_parameter("scroll_speed_y", speed)
