class_name InvestigateState
extends AIState

@export var move_speed: float = 3.5
@export var turn_speed: float = 5.0
@export var max_travel_time: float = 40.0
# Max time to travel as a failsafe
var _timer: float = 0.0

func enter() -> void:
	_timer = 0.0

func physics_update(delta: float) -> void:
	_timer += delta
	entity.move_towards(entity.noise_position, move_speed)
	entity.face_towards(entity.noise_position, turn_speed, delta)
	var on_target_floor := entity.location.floor_id == entity.noise_floor_id
	if on_target_floor or entity.nav_agent.is_navigation_finished() or _timer >= max_travel_time:
		transition_requested.emit("Patrol")

func on_perception_updated(can_see_player: bool, _delta: float) -> void:
	if can_see_player:
		transition_requested.emit("Detect")

func on_noise_alert(_room_id: StringName, _floor_id: int, _world_position: Vector3) -> void:
	entity.respond_to_noise()
