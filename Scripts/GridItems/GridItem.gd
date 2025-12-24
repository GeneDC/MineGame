extends Node3D
class_name GridItem

enum Direction
{
	NORTH,
	EAST,
	SOUTH,
	WEST
}

# Rotates the Direction around right / clockwise. 1 or n times
static func direction_right(dir: Direction, n: int = 1) -> Direction:
	return ((dir + n) % 4) as Direction
	
# Rotates the Direction around left / anti-clockwise. 1 or n times
static func direction_left(dir: Direction, n: int = 1) -> Direction:
	return ((dir + 4 - n) % 4) as Direction

var coodinate: Vector3i = Vector3i.ZERO
var direction := Direction.NORTH

func grid_update(_forward: GridItem, _right: GridItem, 
					_back: GridItem, _left: GridItem, 
					_up: GridItem, _down: GridItem) -> void:
	return
