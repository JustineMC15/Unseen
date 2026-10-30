## Area3D at the exit. The player walking in wins the game.
class_name ExitTrigger
extends Area3D

@export var player_group: String = "player"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(player_group):
		GameState.win()
