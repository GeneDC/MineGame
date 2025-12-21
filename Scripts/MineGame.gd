class_name MineGame

enum OreType {None, Coal, Iron, Gold}

static var _OreTypeToScene: Dictionary[OreType, PackedScene] = {
	OreType.Coal: preload("res://Prefabs/CoalOre.tscn"),
	OreType.Iron: preload("res://Prefabs/IronOre.tscn"),
	OreType.Gold: preload("res://Prefabs/GoldOre.tscn"),
}

static func GetSceneForOreType(Type: OreType) -> PackedScene:
	return _OreTypeToScene[Type]
