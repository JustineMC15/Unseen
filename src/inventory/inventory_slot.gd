extends Panel
class_name InventorySlot

signal slot_clicked(slot_index: int)

@onready var item_icon: TextureRect = $ItemIcon
@onready var selection_border: Panel = $SelectionBorder
@onready var quantity_label: Label = $QuantityLabel
@onready var slot_number: Label = $SlotNumber

var slot_index: int = -1
var is_selected: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	selection_border.mouse_filter = Control.MOUSE_FILTER_IGNORE

	clear_slot()
	update_selection(false)


func setup(index: int) -> void:
	slot_index = index
	slot_number.text = str(index + 1) if index < 9 else "0"


func set_item(texture: Texture2D, quantity: int = 1) -> void:
	item_icon.texture = texture
	item_icon.visible = texture != null

	quantity_label.text = str(quantity) if quantity > 1 else ""
	quantity_label.visible = quantity > 1


func clear_slot() -> void:
	item_icon.texture = null
	item_icon.visible = false

	quantity_label.text = ""
	quantity_label.visible = false


func update_selection(selected: bool) -> void:
	is_selected = selected
	selection_border.visible = selected


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			slot_clicked.emit(slot_index)
			accept_event()
