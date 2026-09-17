class_name DetectState
extends AIState

@export var confirm_time: float = 1.5
@export var give_up_time: float = 3.0
@export var move_speed: float = 3.0

var _confirm_timer: float = 0.0
var _give_up_timer: float = 0.0
var _last_known_position: Vector3

func enter() -> void:
	_confirm_timer = 0.0
	_give_up_timer = 0.0
	_last_known_position = entity.perception.player.global_position

func physics_update(_delta: float) -> void:
	entity.move_towards(_last_known_position, move_speed)

func on_perception_updated(can_see_player: bool, delta: float) -> void:
	if can_see_player:
		_last_known_position = entity.perception.player.global_position
		_give_up_timer = 0.0
		_confirm_timer += delta
		if _confirm_timer >= confirm_time:
			transition_requested.emit("Chase")
	else:
		_confirm_timer = 0.0
		_give_up_timer += delta
		if _give_up_timer >= give_up_time:
			transition_requested.emit("Patrol")
