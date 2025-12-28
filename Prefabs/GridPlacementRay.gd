extends RayCast3D

## self registeres this ray as the placement ray for the factory grid
func _ready() -> void:
	MineManager.factory_grid.register_placement_ray(self)
