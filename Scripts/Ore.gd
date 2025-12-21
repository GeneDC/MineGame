class_name Ore
extends RigidBody3D

@export var Type: MineGame.OreType = MineGame.OreType.None

var PoolIndex: int = -1
var IsActive: bool = false
var _IsPendingActivate: bool = false
var _TargetPosition := Vector3.ZERO
var _LaunchImpulse := Vector3.ZERO


func _ready() -> void:
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	Deactivate()


func Activate(inPosition: Vector3, launchImpulse: Vector3) -> void:
	IsActive = true
	_IsPendingActivate = true
	_TargetPosition = inPosition
	_LaunchImpulse = launchImpulse

	freeze = false
	process_mode = Node.PROCESS_MODE_INHERIT


func Deactivate() -> void:
	IsActive = false
	_IsPendingActivate = false
	_LaunchImpulse = Vector3.ZERO

	freeze = true
	hide()
	process_mode = Node.PROCESS_MODE_DISABLED

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _IsPendingActivate:
		state.transform.origin = _TargetPosition
		# Call reset on the next frame after the physics engine updates
		reset_physics_interpolation.call_deferred()
		_Activate()


func _Activate() -> void:
	_IsPendingActivate = false
	show()

	if _LaunchImpulse != Vector3.ZERO:
		apply_central_impulse(_LaunchImpulse)
