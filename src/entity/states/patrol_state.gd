class_name PatrolState
extends AIState

@export var waypoints: Array[Vector3] = []
@export var move_speed: float = 2.0
@export var turn_speed: float = 4.0

var _waypoint_index: int = 0
var _flinching: bool = false

func enter() -> void:
	_flinching = false
	if waypoints.is_empty():
		push_warning("PatrolState: no waypoints assigned")

func physics_update(delta: float) -> void:
	if _flinching:
		# Hold position, just turn to face whoever is staring.
		entity.face_towards(entity.perception.player.global_position, turn_speed, delta)
		return
	if waypoints.is_empty():
		return
	entity.move_towards(waypoints[_waypoint_index], move_speed)
	if entity.nav_agent.is_navigation_finished():
		_waypoint_index = (_waypoint_index + 1) % waypoints.size()

func on_gaze_changed(is_watched: bool, _watched_duration: float, _delta: float) -> void:
	_flinching = is_watched

func on_perception_updated(can_see_player: bool, _delta: float) -> void:
	if can_see_player:
		transition_requested.emit("Detect")
