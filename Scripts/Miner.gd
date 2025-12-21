extends Node3D
class_name Miner

@export var ore_types: Array[MineGame.OreType] = []

var type_index: int = 0

var _timer: Timer = null

func _ready() -> void:
	_timer = Timer.new()
	add_child(_timer)
	_timer.wait_time = 0.5
	_timer.one_shot = false
	_timer.timeout.connect(SpawnOre)
	_timer.start()

func SpawnOre() -> void:
	var ore_type: MineGame.OreType = ore_types[type_index]
	type_index = (type_index + 1) % ore_types.size()
	if (ore_type == MineGame.OreType.None):
		return

	var launch_impulse := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	MineManager.ore_pool.InstantiateOre(ore_type, global_position, launch_impulse)
