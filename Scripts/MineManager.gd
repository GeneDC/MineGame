extends Node

var orePool: OrePool = null


func _ready() -> void:
	GameImGui.RegisterMainMenuWindow("Debug", "Mine Manager", _ImguiWindow)

	orePool = OrePool.new()
	orePool.name = "OrePool"
	add_child(orePool)


func _ImguiWindow() -> void:
	ImGui.Text("Mine Manager...")
