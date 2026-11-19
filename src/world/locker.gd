## A locker or closet. Press E to climb in, E again to climb out.
## While inside the player is hidden (the entity can't see them, same as a
## HidingSpot), can't walk, and can only look through a limited angle.
## Climbing in and out is a short camera glide; controls are frozen during it.
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
## Seconds for the glide in (the camera also turns to face out of the opening).
@export var enter_time: float = 0.45
## Seconds for the glide back out.
@export var exit_time: float = 0.35

var occupied: bool = false

var _player: Player
var _interactor: Interactor
var _busy: bool = false   # true while a glide is playing
var _tween: Tween

func get_prompt(_interactor_arg: Interactor) -> String:
	if not enabled or _busy:
		return ""
	return "Leave" if occupied else "Hide"

func _on_interact(interactor: Interactor) -> void:
	if _busy:
		return
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
	_busy = true

	# Must happen before the player is moved: it checks whether the entity can
	# see the player where they are standing right now.
	var concealment := _player.hide_component as Concealment
	concealment.enter_hiding_spot(hide_point.global_position)
	if not concealment.is_hidden:
		_interactor.show_feedback("It saw you go in.")

	# Face the player out of the opening (from the hide point toward the exit point).
	var outward := exit_point.global_position - hide_point.global_position
	var yaw := atan2(-outward.x, -outward.z)

	var start := _player.global_position
	var control := exit_point.global_position + Vector3(0.0, _player.feet_offset, 0.0)
	var end := hide_point.global_position + Vector3(0.0, _player.feet_offset, 0.0)

	_player.freeze_controls()
	_interactor.force_focus(self)

	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(
		_glide_in.bind(start, control, end, _player.rotation.y, yaw, _player.head.rotation.x),
		0.0, 1.0, enter_time
	)
	_tween.tween_callback(_finish_enter.bind(yaw))

## t runs 0 -> 1. The position follows a curve that bends through the opening
## (control = exit point), so the player never cuts through a side wall.
func _glide_in(t: float, start: Vector3, control: Vector3, end: Vector3,
		start_yaw: float, end_yaw: float, start_pitch: float) -> void:
	_player.global_position = start.lerp(control, t).lerp(control.lerp(end, t), t)
	_player.rotation.y = lerp_angle(start_yaw, end_yaw, t)
	_player.head.rotation.x = lerpf(start_pitch, 0.0, t)

func _finish_enter(yaw: float) -> void:
	# Hands over to the limited look-around (also resets the camera bob offset).
	_player.lock_controls(yaw, look_half_angle_deg, look_half_pitch_deg)
	_busy = false
	entered.emit()

func _leave() -> void:
	occupied = false
	_busy = true
	(_player.hide_component as Concealment).exit_hiding_spot()
	_interactor.release_focus()
	_player.freeze_controls()

	var end := exit_point.global_position + Vector3(0.0, _player.feet_offset, 0.0)
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_player, "global_position", end, exit_time)
	_tween.tween_callback(_finish_leave)

func _finish_leave() -> void:
	_player.unlock_controls()
	_busy = false
	exited.emit()
