class_name OrePool
extends Node

class Pool:
	extends RefCounted
	var Instances: Array[Ore] = []
	var FreeIndices: Array[int] = []


var PoolMap: Dictionary[MineGame.OreType, Pool] = { }


func _ready() -> void:
	GameImGui.RegisterMainMenuWindow("Debug", "Ore Pool", _ImguiWindow)

	# Instance one of each ore as a way to validate they are setup correctly (InstantiateOre checks for ore type mismatch)
	for oreType: MineGame.OreType in MineGame.OreType.values():
		if (oreType != MineGame.OreType.None):
			InstantiateOre(oreType, Vector3.ZERO, Vector3.ZERO, false)


func InstantiateOre(OreType: MineGame.OreType, position: Vector3, launchImpulse: Vector3, AutoActivate: bool = true) -> void:
	if (OreType == MineGame.OreType.None):
		push_error("Trying to Instantiate Ore with Ore Type `None`")
		return

	var ore: Ore = null

	# Try find or create the Ore Pool for this Ore Type
	var pool: Pool = PoolMap.get(OreType)
	if not pool:
		pool = Pool.new()
		PoolMap[OreType] = pool

	if pool.FreeIndices.is_empty():
		var oreScene := MineGame.GetSceneForOreType(OreType)
		if not oreScene:
			push_error("No Scene found for ore type %s" % MineGame.OreType.find_key(OreType))
			return

		ore = oreScene.instantiate()

		assert(ore.Type == OreType, "Ore type mismatch! Trying to instantiate Ore of type `%s` with scene `%s`, but it has type of `%s`." % [MineGame.OreType.find_key(OreType), oreScene.resource_path, MineGame.OreType.find_key(ore.Type)])
		if (ore.Type != OreType):
			push_error("Ore type mismatch!")
			return

		add_child(ore)
		# Ore id is the index in the pool
		ore.PoolIndex = pool.Instances.size()
		pool.Instances.append(ore)
	else:
		ore = pool.Instances[pool.FreeIndices.pop_back()]

	if AutoActivate:
		ore.Activate(position, launchImpulse)


func FreeOre(ore: Ore) -> void:
	if not ore.IsActive:
		return

	var pool: Pool = PoolMap.get(ore.Type)
	if pool:
		ore.Deactivate()
		pool.FreeIndices.push_back(ore.PoolIndex)


func _ImguiWindow() -> void:
	var ActiveOreCount: int = 0
	var FreeOreCount: int = 0
	for oreType in PoolMap:
		var pool: Pool = PoolMap[oreType]
		var freeCount: int = pool.FreeIndices.size()
		ActiveOreCount += pool.Instances.size() - freeCount
		FreeOreCount += freeCount

	ImGui.Text("Active Ores: %d" % ActiveOreCount)
	ImGui.Text("Free Ores: %d" % FreeOreCount)
	if (ImGui.Button("Clear Ores")):
		for oreType in PoolMap:
			var orePool: Pool = PoolMap[oreType]
			#push_warning("Pre Free - `%s` Ore Instances: %d, Free: %d" % [MineGame.OreType.find_key(oreType), orePool.Instances.size(), orePool.FreeIndices.size()])
			for ore in orePool.Instances:
				FreeOre(ore)
			#push_warning("Post Free - `%s` Ore Instances: %d, Free: %d" % [MineGame.OreType.find_key(oreType), orePool.Instances.size(), orePool.FreeIndices.size()])
