extends Node3D

class_name Miner

@export var OreTypes: Array[MineGame.OreType] = []

var TypeIndex: int = 0

var _Timer: Timer = null


func _ready() -> void:
	_Timer = Timer.new()
	add_child(_Timer)
	_Timer.wait_time = 0.5
	_Timer.one_shot = false
	_Timer.timeout.connect(SpawnOre)
	_Timer.start()


func SpawnOre() -> void:
	var oreType: MineGame.OreType = OreTypes[TypeIndex]
	TypeIndex = (TypeIndex + 1) % OreTypes.size()
	if (oreType == MineGame.OreType.None):
		return

	var launchImpulse := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	MineManager.orePool.InstantiateOre(oreType, global_position, launchImpulse)
