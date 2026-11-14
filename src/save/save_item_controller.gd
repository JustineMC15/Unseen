class_name SaveItemController
extends Node

signal picker_requested
signal saved(slot: int)
signal cancelled

@export var inventory: Inventory
@export var save_system: SaveSystem
# Optional. Used only to show "Game saved." through the usual feedback message.
@export var interactor: Interactor
@export var save_action: StringName = &"save_game"
# If true, each rosary is used up by one save.
@export var consume_item: bool = true

var _pending_inventory_slot: int = -1

func _ready() -> void:
	add_to_group("save_item_controller")
	if inventory == null or save_system == null:
		push_warning("SaveItemController: assign 'inventory' and 'save_system' in the Inspector.")
		return
	inventory.item_used.connect(_on_item_used)

func is_picking() -> bool:
	return _pending_inventory_slot != -1

func _on_item_used(item: ItemData, inventory_slot: int) -> void:
	if item.use_action != save_action or is_picking():
		return
	_pending_inventory_slot = inventory_slot
	picker_requested.emit()

## Called by the UI with the slot the player picked (0-3). Returns true if saved.
func confirm(save_slot: int) -> bool:
	if not is_picking():
		return false
	# The rosary is removed BEFORE saving, so the save file does not contain it.
	# Otherwise loading that save would hand the rosary back for free.
	var used: ItemData = null
	if consume_item:
		used = inventory.remove_item(_pending_inventory_slot)
	var ok := save_system.save_to_slot(save_slot)
	if not ok and used != null:
		inventory.add_item(used)
	_pending_inventory_slot = -1
	if ok:
		saved.emit(save_slot)
		if interactor != null:
			interactor.show_feedback("Game saved.")
	return ok

# Called by the UI when the player backs out of the slot picker. The rosary is kept.
func cancel() -> void:
	if not is_picking():
		return
	_pending_inventory_slot = -1
	cancelled.emit()
