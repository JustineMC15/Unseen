## Area3D placed as a child of the Unseen (AIEntity). If the player is inside it
## while the entity is in one of the lethal states, the run is over.
class_name EntityCatch
extends Area3D

@export var player_group: String = "player"
## State node names in which touching the player is lethal.
@export var catch_state_names: Array[String] = ["Chase", "Detect"]

@onready var _entity := get_parent() as AIEntity

func _physics_process(_delta: float) -> void:
	if _entity == null or not catch_state_names.has(_entity.state_machine.current_state_name):
		return
	# Checked every frame (not body_entered) so a player already standing inside
	# the area when a lethal state starts still gets caught.
	for body in get_overlapping_bodies():
		if body.is_in_group(player_group):
			GameState.game_over()
			return
