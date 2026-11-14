class_name SaveSystem
extends Node

signal slot_saved(slot: int)
signal loaded

const GROUP: StringName = &"saveable"

func _ready() -> void:
	add_to_group("save_system")
	if SaveStore.has_pending():
		_restore_pending()

# Saves the running level into the slot (0-3), overwriting it.
func save_to_slot(slot: int) -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false

	var objects: Dictionary = {}
	var summary: Dictionary = {}
	for node in get_tree().get_nodes_in_group(GROUP):
		var key := str(scene.get_path_to(node))
		if node.has_method("capture_state"):
			objects[key] = node.capture_state()
		if node.has_method("get_save_summary"):
			summary.merge(node.get_save_summary(), true)

	var data: Dictionary = {
		"scene": scene.scene_file_path,
		"summary": summary,
		"objects": objects,
	}
	if not SaveStore.write_slot(slot, data):
		return false
	slot_saved.emit(slot)
	return true

func _restore_pending() -> void:
	# Wait a frame so every other node in the level has finished its _ready().
	await get_tree().process_frame
	var data := SaveStore.take_pending()
	var scene := get_tree().current_scene
	if scene == null or data.is_empty():
		return
	var saved: Dictionary = data.get("objects", {})
	for node in get_tree().get_nodes_in_group(GROUP):
		var key := str(scene.get_path_to(node))
		if saved.has(key):
			if node.has_method("restore_state"):
				node.restore_state(saved[key])
		elif node.has_method("on_missing_from_save"):
			node.on_missing_from_save()
	loaded.emit()
