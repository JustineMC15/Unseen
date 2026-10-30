## Put this on a Node that is a child of the player's Camera3D.
## Shakes with h_offset / v_offset so it doesn't fight the head bob (which moves position).
## Runs while the tree is paused, so the shake still plays on the game over freeze.
class_name CameraShake
extends Node

@export var camera: Camera3D
@export var shake_on_game_over: bool = true
@export var game_over_strength: float = 0.15
@export var game_over_duration: float = 0.8

var _strength: float = 0.0
var _duration: float = 0.0
var _time_left: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if camera == null:
		camera = get_parent() as Camera3D
	GameState.state_changed.connect(_on_game_state_changed)

## strength is in meters of camera offset (0.05 is subtle, 0.2 is violent).
func shake(strength: float, duration: float) -> void:
	_strength = strength
	_duration = maxf(duration, 0.01)
	_time_left = _duration

func _process(delta: float) -> void:
	if _time_left <= 0.0 or camera == null:
		return
	_time_left = maxf(_time_left - delta, 0.0)
	var amount := _strength * (_time_left / _duration)
	camera.h_offset = randf_range(-1.0, 1.0) * amount
	camera.v_offset = randf_range(-1.0, 1.0) * amount

func _on_game_state_changed(_previous: GameState.State, new_state: GameState.State) -> void:
	if shake_on_game_over and new_state == GameState.State.GAME_OVER:
		shake(game_over_strength, game_over_duration)
