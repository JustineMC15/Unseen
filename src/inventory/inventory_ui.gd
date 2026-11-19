
extends Control
class_name InventoryUI

@export var inventory_path: NodePath
@export var slot_scene: PackedScene

var inventory: Inventory

@onready var inventory_grid: GridContainer = $MainMargin/MainLayout/ContentContainer/LeftPanel/InventoryGrid

@onready var item_name_label: Label = $MainMargin/MainLayout/ContentContainer/RightPanel/ItemName
@onready var item_desc_label: RichTextLabel = $MainMargin/MainLayout/ContentContainer/RightPanel/ItemDescription
@onready var action_container: VBoxContainer = $MainMargin/MainLayout/ContentContainer/RightPanel/ActionContainer
@onready var item_preview: TextureRect = $MainMargin/MainLayout/ContentContainer/RightPanel/PreviewFrame/ItemPreview

var inventory_slots: Array[InventorySlot] = []


func _ready() -> void:
	if not inventory_path.is_empty():
		inventory = get_node_or_null(inventory_path) as Inventory

	if inventory == null and get_parent() != null:
		inventory = get_parent().get_node_or_null("Inventory") as Inventory

	# Allow standalone scene editing
	if inventory == null:
		if get_tree().current_scene != self:
			push_error("InventoryUI: Inventory reference is missing.")
		return

	if slot_scene == null:
		push_error("InventoryUI: Slot scene is not assigned.")
		return

	hide()

	_build_inventory_slots()

	inventory.item_added.connect(_on_item_added)
	inventory.item_removed.connect(_on_item_removed)
	inventory.selection_changed.connect(_on_selection_changed)
	inventory.ui_toggled.connect(_on_inventory_toggled)

	_refresh_all_slots()
	_on_selection_changed(inventory.selected_slot)


# BUILD INVENTORY SLOTS
func _build_inventory_slots() -> void:
	# Reuse existing slots if they are already in the scene
	for child in inventory_grid.get_children():
		if child is InventorySlot:
			var slot := child as InventorySlot
			var index := inventory_slots.size()

			slot.setup(index)
			slot.slot_clicked.connect(_on_slot_clicked)
			inventory_slots.append(slot)

	# Create remaining slots if needed
	while inventory_slots.size() < Inventory.MAX_SLOTS:
		var index := inventory_slots.size()
		var slot := slot_scene.instantiate() as InventorySlot

		inventory_grid.add_child(slot)
		slot.setup(index)
		slot.slot_clicked.connect(_on_slot_clicked)

		inventory_slots.append(slot)


# REFRESH ALL SLOTS
func _refresh_all_slots() -> void:
	var current_items := inventory.get_slots()

	for i in range(inventory_slots.size()):
		var item: ItemData = null

		if i < current_items.size():
			item = current_items[i]

		_update_slot_display(i, item)


func _update_slot_display(slot_index: int, item: ItemData) -> void:
	var icon_texture: Texture2D = null

	if item != null:
		icon_texture = item.icon

	if slot_index >= 0 and slot_index < inventory_slots.size():
		inventory_slots[slot_index].set_item(icon_texture)


# UPDATE RIGHT-SIDE ITEM PREVIEW
func _update_details_panel(slot_index: int) -> void:
	if slot_index < 0:
		_clear_details_panel()
		return

	var item: ItemData = inventory.get_item(slot_index)

	if item == null:
		_clear_details_panel()
		return

	var display_name = item.get("display_name")
	var description = item.get("description")

	item_name_label.text = str(display_name) if display_name != null else str(item.get("id"))
	item_desc_label.text = str(description) if description != null else ""

	item_preview.texture = item.icon

	action_container.show()


func _clear_details_panel() -> void:
	item_name_label.text = ""
	item_desc_label.text = ""
	item_preview.texture = null
	action_container.hide()


# ITEM ADDED
func _on_item_added(item: ItemData, slot_index: int) -> void:
	_update_slot_display(slot_index, item)

	if slot_index == inventory.selected_slot:
		_update_details_panel(slot_index)


# ITEM REMOVED
func _on_item_removed(_item: ItemData, slot_index: int) -> void:
	_update_slot_display(slot_index, null)

	if slot_index == inventory.selected_slot:
		_update_details_panel(slot_index)


# SLOT CLICKED
func _on_slot_clicked(slot_index: int) -> void:
	inventory.toggle_slot(slot_index)


# SELECTION CHANGED
func _on_selection_changed(slot_index: int) -> void:
	for i in range(inventory_slots.size()):
		inventory_slots[i].update_selection(i == slot_index)

	_update_details_panel(slot_index)


# INVENTORY OPEN / CLOSE
func _on_inventory_toggled(is_open: bool) -> void:
	visible = is_open

	Input.mouse_mode = (
		Input.MOUSE_MODE_VISIBLE
		if is_open
		else Input.MOUSE_MODE_CAPTURED
	)
