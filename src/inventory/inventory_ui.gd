extends Control

signal item_used(item: ItemData)

const SLOT_COUNT := 10
const EMPTY_DESCRIPTION := "Select an item..."

@onready var grid: GridContainer = %InventoryGrid
@onready var item_name: Label = %ItemName
@onready var item_desc: RichTextLabel = %ItemDescription
@onready var item_preview: TextureRect = %ItemPreview
@onready var use_btn: Button = %UseButton
@onready var close_btn: Button = %CloseButton

var slots: Array[InventorySlot] = []
var items: Array[ItemData] = []
var selected_index: int = -1


func _ready() -> void:
	items.resize(SLOT_COUNT)
	add_item(preload("res://src/item/key_classroom_201.tres"))
	add_item(preload("res://src/item/rosary.tres"))

	for i in grid.get_child_count():
		var slot := grid.get_child(i) as InventorySlot
		if slot == null:
			push_warning("InventoryGrid child %d is not an InventorySlot" % i)
			continue
		slot.setup(i)
		slot.slot_clicked.connect(_on_slot_clicked)
		slots.append(slot)

	use_btn.pressed.connect(_on_use_pressed)
	close_btn.pressed.connect(hide)

	_refresh_slots()
	_select(-1)


# --- Public API (call these from gameplay code) ---

## Puts the item in the first empty slot. Returns false if the inventory is full.
func add_item(item: ItemData) -> bool:
	for i in items.size():
		if items[i] == null:
			items[i] = item
			if is_node_ready():
				_refresh_slots()
			return true
	return false


func remove_item(item: ItemData) -> void:
	var index := items.find(item)
	if index == -1:
		return
	items[index] = null
	_refresh_slots()
	if index == selected_index:
		_select(-1)


func has_item(id: StringName) -> bool:
	for item in items:
		if item != null and item.id == id:
			return true
	return false


# --- Internals ---

func _refresh_slots() -> void:
	for i in slots.size():
		var item := items[i]
		if item:
			slots[i].set_item(item.icon)
		else:
			slots[i].clear_slot()


func _on_slot_clicked(index: int) -> void:
	if items[index] == null:
		return   # empty slots do nothing
	_select(index)


func _select(index: int) -> void:
	selected_index = index
	for i in slots.size():
		slots[i].update_selection(i == index)

	var item: ItemData = items[index] if index >= 0 else null
	if item:
		item_name.text = item.display_name
		item_desc.text = item.description
		item_preview.texture = item.icon
	else:
		item_name.text = ""
		item_desc.text = EMPTY_DESCRIPTION
		item_preview.texture = null

	use_btn.disabled = item == null


func _on_use_pressed() -> void:
	if selected_index < 0:
		return
	var item := items[selected_index]
	print("Use: ", item.display_name, " (action: ", item.use_action, ")")
	item_used.emit(item)
