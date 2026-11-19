class_name PlayerTrigger
extends Area3D

signal triggered

@export var player_group: String = "player"
@export var one_shot: bool = true

var _fired: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if one_shot and _fired:
		return
	if not body.is_in_group(player_group):
		return
	_fired = true
	triggered.emit()
