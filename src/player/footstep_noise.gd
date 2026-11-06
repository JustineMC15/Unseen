class_name FootstepNoise
extends Node

# Based on velocity
@export var walk_loudness: float = 0.15
@export var sprint_loudness: float = 0.4
# Meters walked per step noise.
@export var walk_stride: float = 2.0
@export var sprint_stride: float = 2.5
@export var sprint_action: StringName = &"sprint"

var _body: CharacterBody3D
var _location: LocationTracker
var _distance: float = 0.0

func _ready() -> void:
	_body = get_parent() as CharacterBody3D
	_location = LocationTracker.find_on(_body)

func _physics_process(delta: float) -> void:
	if _body == null or not _body.is_on_floor():
		return
	var speed := Vector2(_body.velocity.x, _body.velocity.z).length()
	if speed < 0.5:
		return
	var sprinting := Input.is_action_pressed(sprint_action)
	_distance += speed * delta
	if _distance < (sprint_stride if sprinting else walk_stride):
		return
	_distance = 0.0
	NoiseManager.emit_noise(
		&"footstep_sprint" if sprinting else &"footstep_walk",
		sprint_loudness if sprinting else walk_loudness,
		_location.room_id if _location else &"",
		_location.floor_id if _location else 0,
		_body.global_position
	)
