extends Node

var ore_pool: OrePool = null

var factory_grid: FactoryGrid = null

func _ready() -> void:
	GameImGui.RegisterMainMenuWindow("Debug", "Mine Manager", _ImguiWindow)

	ore_pool = OrePool.new()
	ore_pool.name = "Ore Pool"
	add_child(ore_pool)

	factory_grid = FactoryGrid.new()
	factory_grid.name = "Factory Grid"
	add_child(factory_grid)

func _process(_delta: float) -> void:
	return

func _ImguiWindow() -> void:
	ImGui.Text("Mine Manager...")
