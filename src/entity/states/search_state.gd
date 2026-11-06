class_name SearchState
extends AIState
# Walk to where player is last seen when chase is lost
# Goes to patrol or detect after
@export var move_speed: float = 3.5
@export var turn_speed: float = 5.0
@export var look_around_time: float = 4.0
# Radians per second while looking around (1.5 for 4s is almost a full turn).
@export var look_turn_speed: float = 1.5
# Search time failsafe
@export var max_search_time: float = 15.0
 
var _search_position: Vector3
var _arrived: bool = false
var _look_timer: float = 0.0
var _total_timer: float = 0.0
 
func enter() -> void:
	_arrived = false
	_look_timer = 0.0
	_total_timer = 0.0
	_search_position = entity.last_known_player_position
 
func physics_update(delta: float) -> void:
	if _search_position.distance_to(entity.last_known_player_position) > 0.5:
		_search_position = entity.last_known_player_position
		_arrived = false
		_look_timer = 0.0
		_total_timer = 0.0
 
	_total_timer += delta
	if _total_timer >= max_search_time:
		transition_requested.emit("Patrol")
		return
 
	if not _arrived:
		entity.move_towards(_search_position, move_speed)
		entity.face_towards(_search_position, turn_speed, delta)
		if entity.nav_agent.is_navigation_finished():
			_arrived = true
		return
 
	entity.rotate_y(look_turn_speed * delta)
	_look_timer += delta
	if _look_timer >= look_around_time:
		transition_requested.emit("Patrol")
 
func on_perception_updated(can_see_player: bool, _delta: float) -> void:
	if can_see_player:
		transition_requested.emit("Detect")
 
func on_noise_alert(_room_id: StringName, _floor_id: int, _world_position: Vector3) -> void:
	entity.respond_to_noise()
