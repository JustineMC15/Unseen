## Put this on a SpotLight3D that is a child of the player's Camera3D.
## Needs an Input Map action named "flashlight" (e.g. F).
class_name Flashlight
extends SpotLight3D

signal toggled(is_on: bool)

@export var toggle_action: StringName = &"flashlight"
@export var starts_on: bool = true

func _ready() -> void:
	visible = starts_on

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(toggle_action) and GameState.is_playing():
		set_on(not visible)

func is_on() -> bool:
	return visible

func set_on(value: bool) -> void:
	if value == visible:
		return
	visible = value
	toggled.emit(value)
