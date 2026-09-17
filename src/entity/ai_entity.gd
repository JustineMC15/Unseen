class_name AIEntity
extends CharacterBody3D

@export var perception: EntityPerception
@export var state_machine: AIStateMachine
@export var nav_agent: NavigationAgent3D

func _ready() -> void:
	add_to_group("gaze_watchable")

func _physics_process(delta: float) -> void:
	state_machine.notify_perception(perception.can_see_player(), delta)
	state_machine.notify_gaze(
		GazeSystem.is_watched(self),
		GazeSystem.get_watched_duration(self),
		delta
	)

## NavigationAgent3D resolves the path; states just say where they
## want to go and how fast.
func move_towards(target_position: Vector3, speed: float) -> void:
	nav_agent.target_position = target_position
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
	else:
		var next_point := nav_agent.get_next_path_position()
		var direction := next_point - global_position
		direction.y = 0.0
		velocity = direction.normalized() * speed
	move_and_slide()

## Turn-to-face without moving — used for Patrol's "flinch" reaction.
func face_towards(target_position: Vector3, turn_speed: float, delta: float) -> void:
	var flat_target := target_position
	flat_target.y = global_position.y
	if global_position.distance_to(flat_target) < 0.01:
		return
	var target_transform := global_transform.looking_at(flat_target, Vector3.UP)
	global_transform.basis = global_transform.basis.slerp(
		target_transform.basis, clamp(turn_speed * delta, 0.0, 1.0)
	)
