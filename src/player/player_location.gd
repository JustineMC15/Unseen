extends Node

var current_room_id: StringName = &""
var current_floor_id: int = -1


func set_location(room_id: StringName, floor_id: int) -> void:
	current_room_id = room_id
	current_floor_id = floor_id
