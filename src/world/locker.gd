## A locker or closet. Press E to climb in, E again to climb out.
## While inside the player is hidden (the entity can't see them, same as a
## HidingSpot), can't walk, and can only look through a limited angle.
class_name Locker
extends Interactable
 
signal entered
signal exited
 
@export var hide_point: Marker3D
@export var exit_point: Marker3D
## How far left/right the player can look while inside.
@export var look_half_angle_deg: float = 50.0
## How far up/down the player can look while inside.
@export var look_half_pitch_deg: float = 25.0
 
var occupied: bool = false
 
var _player: Player
var _interactor: Interactor
 
func get_prompt(_interactor_arg: Interactor) -> String:
	if not enabled:
		return ""
	return "Leave" if occupied else "Hide"
 
func _on_interact(interactor: Interactor) -> void:
	if occupied:
		_leave()
	else:
		_enter(interactor)
 
func _enter(interactor: Interactor) -> void:
	var player := interactor.get_parent() as Player
	if player == null or hide_point == null or exit_point == null:
		push_warning("Locker: needs hide_point, exit_point, and an Interactor under the Player.")
		return
	_player = player
	_interactor = interactor
	occupied = true
 
	# Must happen before the player is moved: it checks whether the entity can
	# see the player where they are standing right now.
	var concealment := _player.hide_component as Concealment
	concealment.enter_hiding_spot(hide_point.global_position)
	if not concealment.is_hidden:
		_interactor.show_feedback("It saw you go in.")
 
	# Face the player out of the opening (from the hide point toward the exit point).
	var outward := exit_point.global_position - hide_point.global_position
	var yaw := atan2(-outward.x, -outward.z)
 
	_player.global_position = hide_point.global_position + Vector3(0.0, _player.feet_offset, 0.0)
	_player.lock_controls(yaw, look_half_angle_deg, look_half_pitch_deg)
	# Keeps the "Leave" prompt up and makes E leave, wherever the player is looking.
	_interactor.force_focus(self)
	entered.emit()
 
func _leave() -> void:
	occupied = false
	_player.global_position = exit_point.global_position + Vector3(0.0, _player.feet_offset, 0.0)
	_player.unlock_controls()
	(_player.hide_component as Concealment).exit_hiding_spot()
	_interactor.release_focus()
	exited.emit()
 
