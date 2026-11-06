class_name RoomZone
extends Area3D

@export var room_id: StringName
@export_range(1, 4) var floor_id: int = 1
# How much the entity prefers this room when patrolling (0 = never, 3 = often).
@export var patrol_weight: float = 1.0
@export var look_around_time: float = 3.0

func _ready() -> void:
	add_to_group("room_zones")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func get_patrol_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for child in get_children():
		if child is Marker3D:
			points.append(child.global_position)
	return points

func _on_body_entered(body: Node3D) -> void:
	var tracker := LocationTracker.find_on(body)
	if tracker:
		tracker.zone_entered(self)

func _on_body_exited(body: Node3D) -> void:
	var tracker := LocationTracker.find_on(body)
	if tracker:
		tracker.zone_exited(self)
