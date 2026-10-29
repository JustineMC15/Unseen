## Area3D placed as a child of the Unseen (AIEntity). If the player is inside it
## while the entity is in the catch state, the run is over.
## Skip this if chase_state.gd already handles catching the player.
class_name EntityCatch
extends Area3D

@export var player_group: String = "player"
@export var catch_state_name: String = "Chase"

@onready var _entity := get_parent() as AIEntity

func _physics_process(_delta: float) -> void:
	if _entity == null or _entity.state_machine.current_state_name != catch_state_name:
		return
	# Checked every frame (not body_entered) so a player already standing inside
	# the area when Chase starts still gets caught.
	for body in get_overlapping_bodies():
		if body.is_in_group(player_group):
			GameState.game_over()
			return
