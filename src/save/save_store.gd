class_name SaveStore
extends RefCounted

const SLOT_COUNT: int = 4
const SAVE_DIR: String = "user://saves"
const SAVE_VERSION: int = 1

static var _pending: Dictionary = {}

static func is_valid_slot(slot: int) -> bool:
	return slot >= 0 and slot < SLOT_COUNT

static func slot_exists(slot: int) -> bool:
	return is_valid_slot(slot) and FileAccess.file_exists(_path(slot))

static func get_slot_info(slot: int) -> Dictionary:
	var data := read_slot(slot)
	if data.is_empty():
		return {"exists": false}
	var saved_at: int = data.get("saved_at", 0)
	var bias_seconds: int = Time.get_time_zone_from_system().bias * 60
	return {
		"exists": true,
		"saved_at": saved_at,
		"saved_at_text": Time.get_datetime_string_from_unix_time(saved_at + bias_seconds, true),
		"scene": data.get("scene", ""),
		"summary": data.get("summary", {}),
	}

# Overwrites the slot. Adds the version and the save time itself.
static func write_slot(slot: int, data: Dictionary) -> bool:
	if not is_valid_slot(slot):
		push_warning("SaveStore: slot %d is not valid (0-%d)." % [slot, SLOT_COUNT - 1])
		return false
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var file := FileAccess.open(_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("SaveStore: cannot write slot %d (error %d)." % [slot, FileAccess.get_open_error()])
		return false
	var stamped := data.duplicate()
	stamped["version"] = SAVE_VERSION
	stamped["saved_at"] = int(Time.get_unix_time_from_system())
	file.store_string(var_to_str(stamped))
	file.close()
	return true

# {} if the slot is empty, unreadable or from an incompatible version.
static func read_slot(slot: int) -> Dictionary:
	if not slot_exists(slot):
		return {}
	var parsed: Variant = str_to_var(FileAccess.get_file_as_string(_path(slot)))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	if parsed.get("version", 0) != SAVE_VERSION:
		push_warning("SaveStore: slot %d has an incompatible save version." % slot)
		return {}
	return parsed

static func delete_slot(slot: int) -> bool:
	if not slot_exists(slot):
		return false
	DirAccess.remove_absolute(_path(slot))
	return true

# Stores the slot's data for the next level and returns the scene path to open.
# Returns "" (and warns) if the slot is empty or its scene is missing.
static func begin_load(slot: int) -> String:
	var data := read_slot(slot)
	if data.is_empty():
		push_warning("SaveStore: slot %d is empty or unreadable." % slot)
		return ""
	var scene_path: String = data.get("scene", "")
	if not ResourceLoader.exists(scene_path):
		push_warning("SaveStore: saved scene not found: '%s'" % scene_path)
		return ""
	_pending = data
	return scene_path

static func has_pending() -> bool:
	return not _pending.is_empty()

# Hands over the waiting data once and clears it.
static func take_pending() -> Dictionary:
	var data := _pending
	_pending = {}
	return data

static func _path(slot: int) -> String:
	return "%s/slot_%d.save" % [SAVE_DIR, slot + 1]
