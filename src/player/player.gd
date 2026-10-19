class_name Player
extends CharacterBody3D

@export var move_speed: float = 4.0
@export var sprint_speed: float = 7.0
@export var mouse_sensitivity: float = 0.003
@export var min_pitch_deg: float = -80.0
@export var max_pitch_deg: float = 80.0

@export var step_height: float = 0.6
@export var step_check_distance: float = 0.6
## Distance from the player's origin down to the bottom of the capsule.
## Capsule is centered at y=0.1 with height 1.8, so the bottom is at -0.8.
@export var feet_offset: float = 0.8
@onready var head: Node3D = $Head
@onready var hide_component: Node = $Hide   # Concealment.gd — exposes `is_hidden`

@export var bob_walk_frequency: float = 10.0
@export var bob_sprint_frequency: float = 15.0
@export var bob_walk_amplitude: float = 0.04
@export var bob_sprint_amplitude: float = 0.08
@export var bob_return_speed: float = 8.0
@onready var camera: Camera3D = $Head/Camera3D
var _bob_time: float = 0.0
var _camera_rest_position: Vector3
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_camera_rest_position = camera.position

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(
			head.rotation.x, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg)
		)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)

func _update_head_bob(delta: float, sprinting: bool) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()

	if is_on_floor() and horizontal_speed > 0.5:
		var frequency := bob_sprint_frequency if sprinting else bob_walk_frequency
		var amplitude := bob_sprint_amplitude if sprinting else bob_walk_amplitude
		_bob_time += delta * frequency
		# Up and down once per step, side to side once per two steps.
		camera.position.y = _camera_rest_position.y + sin(_bob_time) * amplitude
		camera.position.x = _camera_rest_position.x + cos(_bob_time * 0.5) * amplitude * 0.5
	else:
		# Standing still, in the air, or pushing against a wall: ease back to rest.
		_bob_time = 0.0
		camera.position = camera.position.lerp(
			_camera_rest_position, clamp(bob_return_speed * delta, 0.0, 1.0)
		)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	var sprinting := Input.is_action_pressed("sprint")
	var current_speed := sprint_speed if sprinting else move_speed
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		_try_step_up(direction)
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)
		velocity.z = move_toward(velocity.z, 0.0, current_speed)

	move_and_slide()
	_update_head_bob(delta, sprinting)

# Raycast-based stair step: blocked at foot height but clear at
# step height means it's a stair, not a wall snap up onto it.
func _try_step_up(direction: Vector3) -> void:
	if not is_on_floor():
		return

	var space_state := get_world_3d().direct_space_state
	var feet_y := global_position.y - feet_offset
	var origin := Vector3(global_position.x, feet_y, global_position.z)

	# Ray 1: just above the floor. A hit means something is in the way.
	var low_from := origin + Vector3(0, 0.1, 0)
	var low_query := PhysicsRayQueryParameters3D.create(
		low_from, low_from + direction * step_check_distance
	)
	low_query.exclude = [self]
	if space_state.intersect_ray(low_query).is_empty():
		return

	# Ray 2: at step height. A hit here means it's a wall, not a stair.
	var high_from := origin + Vector3(0, step_height, 0)
	var high_to := high_from + direction * step_check_distance
	var high_query := PhysicsRayQueryParameters3D.create(high_from, high_to)
	high_query.exclude = [self]
	if not space_state.intersect_ray(high_query).is_empty():
		return

	# Ray 3: straight down from ray 2's end to find the top of the step.
	var down_query := PhysicsRayQueryParameters3D.create(
		high_to, high_to - Vector3(0, step_height + 0.1, 0)
	)
	down_query.exclude = [self]
	var down_hit := space_state.intersect_ray(down_query)
	if down_hit.is_empty():
		return

	var rise: float = down_hit.position.y - feet_y
	if rise > 0.01 and rise <= step_height:
		global_position.y += rise + 0.02
# Required by EntityPerception (`_player_is_hidden`) lts the
# entity's vision check respect the hiding mechanic.
func is_hidden() -> bool:
	return hide_component.is_hidden
