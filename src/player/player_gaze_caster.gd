class_name PlayerGazeCaster
extends Camera3D

@export var max_gaze_distance: float = 20.0
@export var gaze_half_angle_deg: float = 12.0
@export var watchable_group: String = "gaze_watchable"

func _physics_process(delta: float) -> void:
	var looked_at := _find_gazed_target()

	for target in get_tree().get_nodes_in_group(watchable_group):
		GazeSystem.report(target, target == looked_at, delta)

func _find_gazed_target() -> Node3D:
	var camera_position: Vector3 = global_position
	var camera_forward: Vector3 = -global_transform.basis.z

	var best_target: Node3D = null
	var best_angle: float = gaze_half_angle_deg

	for target in get_tree().get_nodes_in_group(watchable_group):
		var target_node: Node3D = target as Node3D

		if target_node == null:
			continue

		var target_position: Vector3 = target_node.global_position
		target_position.y += 1.5

		var to_target: Vector3 = target_position - camera_position
		var distance: float = to_target.length()

		if distance <= 0.001 or distance > max_gaze_distance:
			continue

		var angle: float = rad_to_deg(
			camera_forward.angle_to(to_target.normalized())
		)

		if angle > best_angle:
			continue

		if not _can_hit_target(target_node):
			continue

		best_angle = angle
		best_target = target_node

	return best_target

func _can_hit_target(target: Node3D) -> bool:
	var space_state := get_world_3d().direct_space_state

	var query := PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + (-global_transform.basis.z) * max_gaze_distance
	)

	query.collide_with_areas = true

	var player := get_parent()
	query.exclude = [player]

	var result := space_state.intersect_ray(query)

	if result.is_empty():
		return false

	var collider: Node = result.collider as Node

	if collider == null:
		return false

	return _belongs_to_target(collider, target)

func _belongs_to_target(collider: Node, target: Node3D) -> bool:
	var current: Node = collider

	while current != null:
		if current == target:
			return true

		current = current.get_parent()

	return false
