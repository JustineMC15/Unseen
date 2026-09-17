## Area3D placed at a hiding spot (locker, under a desk, closet).
class_name HidingSpot
extends Area3D

@export var concealment: Concealment
@export var player_group: String = "player"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(player_group):
		return
	var target := concealment if concealment else body.get_node_or_null("Concealment") as Concealment
	if target:
		target.enter_hiding_spot()

func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group(player_group):
		return
	var target := concealment if concealment else body.get_node_or_null("Concealment") as Concealment
	if target:
		target.exit_hiding_spot()
