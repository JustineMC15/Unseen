## Area3D placed at a hiding spot (locker, under a desk, closet).
class_name HidingSpot
extends Area3D
 
## Optional. If empty, it uses the Concealment node found on the player.
@export var concealment: Concealment
@export var player_group: String = "player"
 
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
 
func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(player_group):
		return
	var target := _get_concealment(body)
	if target:
		target.enter_hiding_spot(global_position)
 
func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group(player_group):
		return
	var target := _get_concealment(body)
	if target:
		target.exit_hiding_spot()
 
func _get_concealment(body: Node) -> Concealment:
	if concealment:
		return concealment
	for child in body.get_children():
		if child is Concealment:
			return child as Concealment
	return null
 
