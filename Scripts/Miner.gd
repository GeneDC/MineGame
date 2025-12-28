extends GridItem
class_name GridItem_Miner

@export var ore_types: Array[MineGame.OreType] = []

@onready var animation_player: AnimationPlayer = $MinerMesh/AnimationPlayer
@onready var ore_spawn_ray: RayCast3D = $OreSpawnRay

var type_index: int = 0

var _ore_timer: Timer = null
var _anim_timer: Timer = null

func _ready() -> void:
	_ore_timer = Timer.new()
	add_child(_ore_timer)
	_ore_timer.wait_time = 0.5
	_ore_timer.one_shot = false
	_ore_timer.timeout.connect(SpawnOre)
	
	_anim_timer = Timer.new()
	add_child(_anim_timer)
	_anim_timer.one_shot = true
	
	start_miner()

func start_miner() -> void:
	_anim_timer.wait_time = animation_player.get_animation("Start").length
	_anim_timer.timeout.connect(start_ore_spawning)
	
	animation_player.play("Start")
	_anim_timer.start()

func start_ore_spawning() -> void:
	animation_player.play("Mining")
	_ore_timer.start()

func stop_ore_spawning() -> void:
	_ore_timer.stop()
	animation_player.play("Stop")

func SpawnOre() -> void:
	var ore_type: MineGame.OreType = ore_types[type_index]
	type_index = (type_index + 1) % ore_types.size()
	if (ore_type == MineGame.OreType.None):
		return

	var launch_impulse := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * ore_spawn_ray.global_transform.basis.z.normalized()
	MineManager.ore_pool.InstantiateOre(ore_type, ore_spawn_ray.global_position, launch_impulse)
	
