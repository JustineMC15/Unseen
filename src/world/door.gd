## Swinging door. The node's origin is the hinge, so place it at the hinge edge.
## Leave required_item_id empty for a door that is never locked.
class_name Door
extends Interactable

signal unlocked
signal opened
signal closed

@export var required_item_id: StringName = &""
@export var consume_item: bool = true
@export var open_angle_deg: float = 90.0
@export var open_time: float = 0.6
@export var locked_message: String = "It's locked."
@export var open_loudness: float = 0.5
# Noise when fail to open
@export var locked_loudness: float = 0.4

var is_locked: bool = false
var is_open: bool = false

var _closed_y: float = 0.0
var _tween: Tween

func _ready() -> void:
	is_locked = required_item_id != &""
	_closed_y = rotation.y

func get_prompt(interactor: Interactor) -> String:
	if not enabled:
		return ""
	if is_open:
		return "Close"
	if not is_locked:
		return "Open"
	var held := interactor.inventory.get_selected_item()
	if held != null and held.id == required_item_id:
		return "Unlock with %s" % held.display_name
	return "Locked"

func _on_interact(interactor: Interactor) -> void:
	if is_locked and not _try_unlock(interactor):
		_emit_noise(interactor, &"door_locked", locked_loudness)
		return
	_set_open(not is_open)
	_emit_noise(interactor, &"door_open" if is_open else &"door_close", open_loudness)

func _emit_noise(interactor: Interactor, noise_type: StringName, loudness: float) -> void:
	var tracker := LocationTracker.find_on(interactor.get_parent())
	NoiseManager.emit_noise(
		noise_type,
		loudness,
		tracker.room_id if tracker else &"",
		tracker.floor_id if tracker else 0,
		global_position
	)

func _try_unlock(interactor: Interactor) -> bool:
	var inventory := interactor.inventory
	var held := inventory.get_selected_item()
	if held == null:
		interactor.show_feedback(locked_message)
		return false
	if held.id != required_item_id:
		interactor.show_feedback("The %s doesn't fit." % held.display_name)
		return false
	if consume_item:
		inventory.remove_item(inventory.selected_slot)
	is_locked = false
	unlocked.emit()
	return true

func _set_open(value: bool) -> void:
	is_open = value
	if _tween:
		_tween.kill()
	var target := _closed_y
	if is_open:
		target += deg_to_rad(open_angle_deg)
	_tween = create_tween()
	_tween.tween_property(self, "rotation:y", target, open_time)
	if is_open:
		opened.emit()
	else:
		closed.emit()
