extends Button
class_name InventorySlot

signal slot_clicked(slot_index: int)

@onready var item_icon: TextureRect = $ItemIcon
@onready var selection_border: Panel = $SelectionBorder
@onready var quantity_label: Label = $QuantityLabel
@onready var slot_number: Label = $SlotNumber

var slot_index: int = -1
var is_selected: bool = false


func _ready() -> void:
	toggle_mode = false             # selection is shown by the border, not by toggling
	focus_mode = Control.FOCUS_NONE # no focus rectangle after clicking
	text = ""

	# Children must never swallow clicks meant for the button.
	for child: Control in [item_icon, selection_border, quantity_label, slot_number]:
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE

	pressed.connect(_on_pressed)

	clear_slot()
	update_selection(false)


func setup(index: int) -> void:
	slot_index = index
	slot_number.text = str(index + 1) if index < 9 else "0"


func set_item(texture: Texture2D, quantity: int = 1) -> void:
	item_icon.texture = texture
	item_icon.visible = texture != null

	var show_quantity := texture != null and quantity > 1
	quantity_label.text = str(quantity) if show_quantity else ""
	quantity_label.visible = show_quantity


func clear_slot() -> void:
	item_icon.texture = null
	item_icon.visible = false

	quantity_label.text = ""
	quantity_label.visible = false


func update_selection(selected: bool) -> void:
	is_selected = selected
	selection_border.visible = selected


func _on_pressed() -> void:
	slot_clicked.emit(slot_index)
