class_name ChaseState
extends AIState

@export var base_speed: float = 5.0
@export var watched_speed_multiplier: float = 1.6
@export var give_up_time: float = 4.0

var _is_watched: bool = false
var _give_up_timer: float = 0.0

func enter() -> void:
	_is_watched = false
	_give_up_timer = 0.0

func physics_update(_delta: float) -> void:
	var speed := base_speed * (watched_speed_multiplier if _is_watched else 1.0)
	entity.move_towards(entity.perception.player.global_position, speed)

func on_gaze_changed(is_watched: bool, _watched_duration: float, _delta: float) -> void:
	_is_watched = is_watched

func on_perception_updated(can_see_player: bool, delta: float) -> void:
	if can_see_player:
		_give_up_timer = 0.0
	else:
		_give_up_timer += delta
		if _give_up_timer >= give_up_time:
			transition_requested.emit("Patrol")
