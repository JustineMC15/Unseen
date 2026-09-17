class_name EntityPerception
extends Node

@export var eyes: Node3D                # empty marker at head height, facing forward
@export var player: Node3D
@export var vision_range: float = 10.0
@export var vision_half_angle_deg: float = 40.0
@export var player_group: String = "player"

func _ready() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group(player_group)

func can_see_player() -> bool:
	if player == null or eyes == null:
		return false
	if _player_is_hidden():
		return false
	var to_player := player.global_position - eyes.global_position
	var distance := to_player.length()
	if distance > vision_range:
		return false
	var forward := -eyes.global_transform.basis.z
	var angle := rad_to_deg(forward.angle_to(to_player.normalized()))
	if angle > vision_half_angle_deg:
		return false
	return _has_line_of_sight()

func _has_line_of_sight() -> bool:
	var space_state := eyes.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(eyes.global_position, player.global_position)
	query.exclude = [eyes.get_parent()]
	var result := space_state.intersect_ray(query)
	return result.is_empty() or result.collider == player

func _player_is_hidden() -> bool:
	return player.has_method("is_hidden") and player.is_hidden()
