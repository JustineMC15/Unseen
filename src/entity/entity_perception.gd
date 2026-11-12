class_name EntityPerception
extends Node

@export var eyes: Node3D
@export var player: Node3D
@export var vision_range: float = 15.0
@export var vision_half_angle_deg: float = 40.0
@export var player_group: String = "player"
## Heights, relative to the player's origin, that the entity tries to see.
## Head, chest, legs. Seeing any one of them counts as seeing the player.
@export var sight_point_offsets: Array[float] = [0.8, 0.2, -0.5]

func _ready() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group(player_group)

func can_see_player() -> bool:
	if player == null or eyes == null:
		return false

	if _player_is_hidden():
		return false

	var to_player := player.global_position - eyes.global_position
	if to_player.length() > vision_range:
		return false

	# Sideways angle only, so height differences on ramps don't shrink the cone.
	var forward := -eyes.global_transform.basis.z
	var flat_forward := Vector3(forward.x, 0.0, forward.z).normalized()
	var flat_to := Vector3(to_player.x, 0.0, to_player.z)
	if flat_to.length() > 0.01:
		var angle := rad_to_deg(flat_forward.angle_to(flat_to.normalized()))
		if angle > vision_half_angle_deg:
			return false

	return _has_line_of_sight()

func _has_line_of_sight() -> bool:
	var space_state := eyes.get_world_3d().direct_space_state
	for y_offset in sight_point_offsets:
		var query := PhysicsRayQueryParameters3D.create(
			eyes.global_position,
			player.global_position + Vector3.UP * y_offset
		)
		query.exclude = [eyes.get_parent()]
		var result := space_state.intersect_ray(query)
		if result.is_empty() or result.collider == player:
			return true
	return false

func _player_is_hidden() -> bool:
	return player.has_method("is_hidden") and player.is_hidden()
