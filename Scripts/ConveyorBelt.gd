extends StaticBody3D

@export var speed: float = 0.2

func _ready() -> void:
	update_conveyor_velocity()

func update_conveyor_velocity() -> void:
	# Conveyor mesh is setup to face positive x
	constant_linear_velocity = global_transform.basis.z * speed
