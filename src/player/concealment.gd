class_name Concealment
extends Node

signal concealment_broken

@export var entity: AIEntity
@export var reveal_time: float = 2.0

var is_hidden: bool = false
var _reveal_timer: float = 0.0

func enter_hiding_spot() -> void:
	is_hidden = true
	_reveal_timer = 0.0

func exit_hiding_spot() -> void:
	is_hidden = false
	_reveal_timer = 0.0

func _physics_process(delta: float) -> void:
	if not is_hidden or entity == null:
		return
	if GazeSystem.is_watched(entity):
		_reveal_timer += delta
		if _reveal_timer >= reveal_time:
			_break_concealment()
	else:
		_reveal_timer = max(_reveal_timer - delta, 0.0)

func _break_concealment() -> void:
	is_hidden = false
	_reveal_timer = 0.0
	concealment_broken.emit()
	entity.state_machine.force_transition("Detect")
