# Goes in map, attach to Node3D
# Has Marker3D children, Patrol goes in order of
# children then loops back
class_name PatrolRoute
extends Node3D

func get_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for child in get_children():
		if child is Marker3D:
			points.append(child.global_position)
	return points
