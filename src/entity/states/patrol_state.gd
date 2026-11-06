class_name PatrolState
extends AIState

@export var route: PatrolRoute
@export var move_speed: float = 2.0
@export var turn_speed: float = 4.0
@export var look_turn_speed: float = 1.0
@export var min_rooms_per_floor: int = 3
# Chance (0-1) of leaving for an adjacent floor once min_rooms_per_floor is met.
@export_range(0.0, 1.0) var floor_change_chance: float = 0.3
# The last N visited rooms are skipped when picking the next one.
@export var recent_memory: int = 2

var _has_target: bool = false
var _target_point: Vector3
var _target_look_time: float = 0.0
var _look_left: float = 0.0
var _flinching: bool = false
var _recent_rooms: Array[StringName] = []
var _rooms_on_floor: int = 0
var _last_floor: int = 0

# Fallback route state.
var _waypoints: Array[Vector3] = []
var _waypoint_index: int = 0

func enter() -> void:
	_flinching = false
	_has_target = false
	_look_left = 0.0
	if route != null:
		_waypoints = route.get_points()
	else:
		_waypoints = []
	_waypoint_index = clampi(_waypoint_index, 0, maxi(_waypoints.size() - 1, 0))

func physics_update(delta: float) -> void:
	if _flinching:
		# Stand and turn to player when staring
		entity.face_towards(entity.perception.player.global_position, turn_speed, delta)
		return

	if _look_left > 0.0:
		_look_left -= delta
		entity.rotate_y(look_turn_speed * delta)
		return

	if not _has_target:
		_choose_target()
		if not _has_target:
			_follow_route()
			return

	entity.move_towards(_target_point, move_speed)
	entity.face_towards(_target_point, turn_speed, delta)
	if entity.nav_agent.is_navigation_finished():
		_has_target = false
		_look_left = _target_look_time

func on_gaze_changed(is_watched: bool, _watched_duration: float, _delta: float) -> void:
	_flinching = is_watched

func on_perception_updated(can_see_player: bool, _delta: float) -> void:
	if can_see_player:
		transition_requested.emit("Detect")

func on_noise_alert(_room_id: StringName, _floor_id: int, _world_position: Vector3) -> void:
	entity.respond_to_noise()

func _choose_target() -> void:
	_has_target = false
	var current_floor := entity.location.floor_id
	if current_floor != _last_floor:
		_last_floor = current_floor
		_rooms_on_floor = 0

	var target_floor := current_floor
	if _rooms_on_floor >= min_rooms_per_floor and randf() < floor_change_chance:
		target_floor = _pick_adjacent_floor(current_floor)

	var zone := _pick_zone(target_floor)
	if zone == null:
		return

	var points := zone.get_patrol_points()
	if points.is_empty():
		_target_point = zone.global_position
	else:
		_target_point = points[randi() % points.size()]
	_target_look_time = zone.look_around_time
	_has_target = true
	_rooms_on_floor += 1

	_recent_rooms.append(zone.room_id)
	while _recent_rooms.size() > recent_memory:
		_recent_rooms.pop_front()

func _pick_zone(floor_id: int) -> RoomZone:
	var zones: Array[RoomZone] = []
	for node in get_tree().get_nodes_in_group("room_zones"):
		var zone := node as RoomZone
		if zone != null and zone.floor_id == floor_id and zone.patrol_weight > 0.0:
			zones.append(zone)
	if zones.is_empty():
		return null

	# Skip recently visited rooms unless no other choices
	var pool: Array[RoomZone] = []
	for zone in zones:
		if not _recent_rooms.has(zone.room_id):
			pool.append(zone)
	if pool.is_empty():
		pool = zones

	var total := 0.0
	for zone in pool:
		total += zone.patrol_weight
	var roll := randf() * total
	for zone in pool:
		roll -= zone.patrol_weight
		if roll <= 0.0:
			return zone
	return pool.back()

func _pick_adjacent_floor(current_floor: int) -> int:
	var floors: Array[int] = []
	for node in get_tree().get_nodes_in_group("room_zones"):
		var zone := node as RoomZone
		if zone != null and absi(zone.floor_id - current_floor) == 1 and not floors.has(zone.floor_id):
			floors.append(zone.floor_id)
	if floors.is_empty():
		return current_floor
	return floors[randi() % floors.size()]

func _follow_route() -> void:
	if _waypoints.is_empty():
		return
	entity.move_towards(_waypoints[_waypoint_index], move_speed)
	entity.face_towards(_waypoints[_waypoint_index], turn_speed, get_physics_process_delta_time())
	if entity.nav_agent.is_navigation_finished():
		_waypoint_index = (_waypoint_index + 1) % _waypoints.size()
