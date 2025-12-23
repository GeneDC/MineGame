extends StaticBody3D
class_name ConveyorBelt

func update_conveyor_velocity(speed: float) -> void:
	constant_linear_velocity = global_transform.basis.z * speed
