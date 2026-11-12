class_name AIEntity
extends CharacterBody3D

@export var perception: EntityPerception
@export var state_machine: AIStateMachine
@export var nav_agent: NavigationAgent3D

## How close (flat, height ignored) the entity must get to a point on the red line
## before it turns toward the next one. Smaller = takes corners tighter.
@export var path_reach: float = 0.2
@export var repath_interval: float = 0.4

var location: LocationTracker
var hearing: EntityHearing

# Where the entity believes the player is, from sight or noise.
# Updated every frame the entity can see the player. Used by Chase and Search.
var last_known_player_position: Vector3

var noise_room_id: StringName = &""
var noise_floor_id: int = 0
var noise_position: Vector3

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _path: PackedVector3Array = PackedVector3Array()
var _path_index: int = 0
var _path_target: Vector3 = Vector3.INF
var _repath_left: float = 0.0
var _move_direction: Vector3 = Vector3.ZERO

func _ready() -> void:
	add_to_group("gaze_watchable")
	floor_snap_length = 0.5
	for child in get_children():
		if child is LocationTracker:
			location = child as LocationTracker
		elif child is EntityHearing:
			hearing = child as EntityHearing
	if location == null:
		push_warning("AIEntity: add a LocationTracker child.")
	if hearing:
		hearing.noise_alert.connect(_on_noise_alert)

func _physics_process(delta: float) -> void:
	var sees_player := perception.can_see_player()
	if sees_player:
		last_known_player_position = perception.player.global_position
	state_machine.notify_perception(sees_player, delta)
	state_machine.notify_gaze(
		GazeSystem.is_watched(self),
		GazeSystem.get_watched_duration(self),
		delta
	)

# Called by the states that respond to noise
func respond_to_noise() -> void:
	if noise_floor_id != location.floor_id:
		state_machine.force_transition("Investigate")
	else:
		last_known_player_position = noise_position
		state_machine.force_transition("Search")

func _on_noise_alert(room_id: StringName, floor_id: int, world_position: Vector3) -> void:
	noise_room_id = room_id
	noise_floor_id = floor_id
	noise_position = world_position
	state_machine.notify_noise(room_id, floor_id, world_position)

func move_towards(target_position: Vector3, speed: float) -> void:
	var delta := get_physics_process_delta_time()

	# Kept as before: the states still ask nav_agent.is_navigation_finished().
	nav_agent.target_position = target_position

	# Recalculate the path when the target moved, or every repath_interval seconds.
	_repath_left -= delta
	if _path.is_empty() or _repath_left <= 0.0 or _path_target.distance_to(target_position) > 0.5:
		_path = NavigationServer3D.map_get_path(
			nav_agent.get_navigation_map(), global_position, target_position, true
		)
		_path_index = 0
		_path_target = target_position
		_repath_left = repath_interval

	var horizontal := Vector3.ZERO
	if not _path.is_empty():
		# Never smaller than one frame of travel, so a fast entity can't jump past a point.
		var reach := maxf(path_reach, speed * delta * 1.5)
		while _path_index < _path.size() - 1 and _flat_distance_to(_path[_path_index]) < reach:
			_path_index += 1
		var to_point := _path[_path_index] - global_position
		to_point.y = 0.0
		if to_point.length() > 0.05:
			horizontal = to_point.normalized() * speed
	_move_direction = horizontal.normalized()
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	move_and_slide()

func _flat_distance_to(point: Vector3) -> float:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length()

func face_towards(target_position: Vector3, turn_speed: float, delta: float) -> void:
	var flat_target := target_position
	flat_target.y = global_position.y
	if global_position.distance_to(flat_target) < 0.01:
		return
	var current := global_transform.basis.get_rotation_quaternion()
	var wanted := global_transform.looking_at(flat_target, Vector3.UP).basis.get_rotation_quaternion()
	var turned := current.slerp(wanted, clamp(turn_speed * delta, 0.0, 1.0))
	global_transform.basis = Basis(turned)

## Turns toward the direction the body is actually walking (the next stretch of the path).
func face_movement(turn_speed: float, delta: float) -> void:
	if _move_direction == Vector3.ZERO:
		return
	face_towards(global_position + _move_direction, turn_speed, delta)
