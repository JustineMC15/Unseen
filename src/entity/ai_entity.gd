class_name AIEntity
extends CharacterBody3D

@export var perception: EntityPerception
@export var state_machine: AIStateMachine
@export var nav_agent: NavigationAgent3D

var location: LocationTracker
var hearing: EntityHearing

# Where the entity believes the player is, from sight or noise.
# Updated every frame the entity can see the player. Used by Chase and Search.
var last_known_player_position: Vector3

var noise_room_id: StringName = &""
var noise_floor_id: int = 0
var noise_position: Vector3

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

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
	nav_agent.target_position = target_position
	var horizontal := Vector3.ZERO
	if not nav_agent.is_navigation_finished():
		var direction := nav_agent.get_next_path_position() - global_position
		direction.y = 0.0
		horizontal = direction.normalized() * speed
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * get_physics_process_delta_time()
	move_and_slide()

func face_towards(target_position: Vector3, turn_speed: float, delta: float) -> void:
	var flat_target := target_position
	flat_target.y = global_position.y
	if global_position.distance_to(flat_target) < 0.01:
		return
	var current := global_transform.basis.get_rotation_quaternion()
	var wanted := global_transform.looking_at(flat_target, Vector3.UP).basis.get_rotation_quaternion()
	var turned := current.slerp(wanted, clamp(turn_speed * delta, 0.0, 1.0))
	global_transform.basis = Basis(turned)
