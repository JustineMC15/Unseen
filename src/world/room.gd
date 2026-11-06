extends Node3D

func _ready() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var tracker := LocationTracker.find_on(player)
	tracker.location_changed.connect(_on_player_location_changed)

func _on_player_location_changed(room_id: StringName, floor_id: int) -> void:
	pass
