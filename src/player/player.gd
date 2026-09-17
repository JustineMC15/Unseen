class_name Player
extends CharacterBody3D

@export var move_speed: float = 4.0
@export var mouse_sensitivity: float = 0.003
@export var min_pitch_deg: float = -80.0
@export var max_pitch_deg: float = 80.0

@onready var head: Node3D = $Head
@onready var hide_component: Node = $Hide   # Concealment.gd — exposes `is_hidden`

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)

	move_and_slide()

## Required by EntityPerception (`_player_is_hidden`) — lets the
## entity's vision check respect the hiding mechanic.
func is_hidden() -> bool:
	return hide_component.is_hidden
