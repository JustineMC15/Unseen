class_name ScareTrigger
extends Area3D

@export var entity: AIEntity
@export var reveal_position: Vector3
@export var lights: Array[Light3D] = []
@export var chase_gaze_threshold: float = 1.0
@export var player_group: String = "player"

var _triggered: bool = false
var _revealing: bool = false
var _reveal_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if _triggered or not body.is_in_group(player_group):
		return
	_triggered = true
	_start_scare()

func _start_scare() -> void:
	for light in lights:
		light.visible = false
	entity.global_position = reveal_position
	_revealing = true
	_reveal_timer = 0.0

func _physics_process(delta: float) -> void:
	if not _revealing:
		return
	if GazeSystem.is_watched(entity):
		_reveal_timer += delta
		if _reveal_timer >= chase_gaze_threshold:
			_end_scare("Chase")
	else:
		_end_scare("Patrol")

func _end_scare(next_state: String) -> void:
	_revealing = false
	entity.state_machine.force_transition(next_state)
	for light in lights:
		light.visible = true
