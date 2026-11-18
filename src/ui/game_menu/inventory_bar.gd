## Shows the Inventory's 10 slots on Randy's layout. It only listens to Inventory signals.
## Layout rule: "slots_container" has one child Control per slot, in slot order (slot 1 first).
## Inside each slot, the first TextureRect shows the item icon and the first Label shows
## the item name. Both are optional, and a slot with extra decoration (frame, background)
## is fine. Put the slot NUMBER label outside the slot, or it would be overwritten.
## "inventory" is optional: if empty, it is found on the node in group "player".
class_name InventoryBar
extends Control

@export var inventory: Inventory
@export var slots_container: Control
@export var normal_modulate: Color = Color.WHITE
@export var empty_modulate: Color = Color(1.0, 1.0, 1.0, 0.4)
@export var selected_modulate: Color = Color(1.0, 0.85, 0.3)
## True: the bar only shows while the inventory is open (Tab). False: always visible.
@export var show_only_when_open: bool = false

var _slots: Array[Control] = []
var _icons: Array[TextureRect] = []
var _names: Array[Label] = []

func _ready() -> void:
	if slots_container == null:
		push_warning("InventoryBar: assign 'slots_container' in the inspector.")
		return
	for child in slots_container.get_children():
		var slot := child as Control
		if slot == null:
			continue
		_slots.append(slot)
		_icons.append(_find_icon(slot))
		_names.append(_find_name(slot))
	if inventory == null:
		# Wait a frame so the Player has joined the "player" group.
		await get_tree().process_frame
		inventory = _find_inventory()
	if inventory == null:
		push_warning("InventoryBar: no Inventory assigned and none found under the player.")
		return
	inventory.item_added.connect(_on_slot_changed)
	inventory.item_removed.connect(_on_slot_changed)
	inventory.selection_changed.connect(_on_selection_changed)
	if show_only_when_open:
		visible = inventory.is_ui_open
		inventory.ui_toggled.connect(_on_ui_toggled)
	_refresh()

func _find_inventory() -> Inventory:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return null
	for child in player.get_children():
		if child is Inventory:
			return child as Inventory
	return null

func _find_icon(node: Node) -> TextureRect:
	for child in node.get_children():
		if child is TextureRect:
			return child as TextureRect
		var deeper := _find_icon(child)
		if deeper != null:
			return deeper
	return null

func _find_name(node: Node) -> Label:
	for child in node.get_children():
		if child is Label:
			return child as Label
		var deeper := _find_name(child)
		if deeper != null:
			return deeper
	return null

func _on_slot_changed(_item: ItemData, _slot: int) -> void:
	_refresh()

func _on_selection_changed(_slot: int) -> void:
	_refresh()

func _on_ui_toggled(is_open: bool) -> void:
	visible = is_open

func _refresh() -> void:
	var items := inventory.get_slots()
	for i in mini(_slots.size(), items.size()):
		var item := items[i]
		if _icons[i]:
			_icons[i].texture = item.icon if item != null else null
		if _names[i]:
			_names[i].text = item.display_name if item != null else ""
		if i == inventory.selected_slot:
			_slots[i].modulate = selected_modulate
		else:
			_slots[i].modulate = normal_modulate if item != null else empty_modulate
