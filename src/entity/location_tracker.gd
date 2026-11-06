class_name LocationTracker
extends Node

signal location_changed(room_id: StringName, floor_id: int)

var room_id: StringName = &""
# Records the current room the entity is in
var floor_id: int = 0
# Starts with 0, not in any room yet

# Zones the body is inside right now, most recently entered last.
var _zones: Array[RoomZone] = []

static func find_on(node: Node) -> LocationTracker:
	if node == null:
		return null
	for child in node.get_children():
		if child is LocationTracker:
			return child as LocationTracker
	return null

func zone_entered(zone: RoomZone) -> void:
	_zones.erase(zone)
	_zones.append(zone)
	_refresh()

func zone_exited(zone: RoomZone) -> void:
	_zones.erase(zone)
	_refresh()

func _refresh() -> void:
	if _zones.is_empty():
		return # Between rooms: keep the last known location.
	var zone: RoomZone = _zones.back()
	if zone.room_id == room_id and zone.floor_id == floor_id:
		return
	room_id = zone.room_id
	floor_id = zone.floor_id
	location_changed.emit(room_id, floor_id)
