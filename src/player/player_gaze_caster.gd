class_name PlayerGazeCaster
extends Node

@export var camera: Camera3D
@export var max_gaze_distance: float = 15.0
@export var watchable_group: String = "gaze_watchable"

func _physics_process(delta: float) -> void:
	if camera == null:
		return
	var looked_at := _raycast_center()
	for target in get_tree().get_nodes_in_group(watchable_group):
		GazeSystem.report(target, target == looked_at, delta)

func _raycast_center() -> Node3D:
	var from := camera.global_position
	var to := from + (-camera.global_transform.basis.z) * max_gaze_distance
	var space_state := camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return null
	var collider: Node = result.collider
	return collider if collider.is_in_group(watchable_group) else null
