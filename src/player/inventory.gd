## Fixed 10 slots, one item per slot, no dropping.
## Only data and signals here; Randy's UI just listens and calls select_slot().
class_name Inventory
extends Node

signal item_added(item: ItemData, slot: int)
signal item_removed(item: ItemData, slot: int)
signal selection_changed(slot: int)

const MAX_SLOTS: int = 10

## -1 means nothing selected.
var selected_slot: int = -1

var _slots: Array[ItemData] = []

func _init() -> void:
	_slots.resize(MAX_SLOTS)

## Returns false if every slot is taken.
func add_item(item: ItemData) -> bool:
	var slot := _slots.find(null)
	if slot == -1:
		return false
	_slots[slot] = item
	item_added.emit(item, slot)
	return true

## Used items are removed this way. Returns the removed item (null if the slot was empty).
func remove_item(slot: int) -> ItemData:
	if slot < 0 or slot >= MAX_SLOTS or _slots[slot] == null:
		return null
	var item := _slots[slot]
	_slots[slot] = null
	item_removed.emit(item, slot)
	return item

func has_item(id: StringName) -> bool:
	for item in _slots:
		if item != null and item.id == id:
			return true
	return false

func is_full() -> bool:
	return not _slots.has(null)

func get_item(slot: int) -> ItemData:
	if slot < 0 or slot >= MAX_SLOTS:
		return null
	return _slots[slot]

## Always MAX_SLOTS long; empty slots are null.
func get_slots() -> Array[ItemData]:
	return _slots.duplicate()

func select_slot(slot: int) -> void:
	if slot < -1 or slot >= MAX_SLOTS or slot == selected_slot:
		return
	selected_slot = slot
	selection_changed.emit(slot)

func get_selected_item() -> ItemData:
	return get_item(selected_slot)

## Pressing the selected slot's key again deselects it.
func toggle_slot(slot: int) -> void:
	select_slot(-1 if slot == selected_slot else slot)

## Wraps around. From "nothing selected", +1 goes to slot 0 and -1 goes to the last slot.
func cycle_selection(step: int) -> void:
	if selected_slot == -1:
		select_slot(0 if step > 0 else MAX_SLOTS - 1)
	else:
		select_slot(posmod(selected_slot + step, MAX_SLOTS))

## The mouse is captured while playing, so the UI can't be clicked.
## Number keys 1-9 and 0 pick slots 1-10; the mouse wheel cycles.
func _unhandled_input(event: InputEvent) -> void:
	if not GameState.is_playing():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var keycode: int = event.physical_keycode
		if keycode >= KEY_1 and keycode <= KEY_9:
			toggle_slot(keycode - KEY_1)
		elif keycode == KEY_0:
			toggle_slot(9)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cycle_selection(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cycle_selection(1)
