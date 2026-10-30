## TEMPORARY. Shows what the Interactor and Inventory report, so you can test
## without Randy's UI. Delete this once his HUD is in.
## Add a CanvasLayer node to the test world and attach this script.
extends CanvasLayer

var _prompt: Label
var _feedback: Label
var _items: Label
var _inventory: Inventory

func _ready() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_top = -150.0
	box.offset_bottom = -20.0
	add_child(box)
	_feedback = _make_label(box)
	_prompt = _make_label(box)
	_items = _make_label(box)

	# Wait one frame so the Player has joined the "player" group.
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("DebugHUD: no node in group 'player'.")
		return
	var interactor := player.get_node_or_null("Interactor") as Interactor
	_inventory = player.get_node_or_null("Inventory") as Inventory
	if interactor == null or _inventory == null:
		push_warning("DebugHUD: Player needs 'Interactor' and 'Inventory' child nodes.")
		return
	interactor.prompt_changed.connect(_on_prompt_changed)
	interactor.feedback.connect(_on_feedback)
	_inventory.item_added.connect(func(_item, _slot): _refresh_items())
	_inventory.item_removed.connect(func(_item, _slot): _refresh_items())
	_inventory.selection_changed.connect(func(_slot): _refresh_items())
	_refresh_items()

func _make_label(parent: Control) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label

func _on_prompt_changed(text: String) -> void:
	_prompt.text = ("[E] " + text) if text != "" else ""

func _on_feedback(text: String) -> void:
	_feedback.text = text
	get_tree().create_timer(2.0).timeout.connect(
		func(): if _feedback.text == text: _feedback.text = ""
	)

func _refresh_items() -> void:
	var parts: Array[String] = []
	var slots := _inventory.get_slots()
	for i in slots.size():
		if slots[i] != null:
			var marker := ">" if i == _inventory.selected_slot else ""
			# The 10th slot is the 0 key.
			parts.append("%s[%d] %s" % [marker, (i + 1) % 10, slots[i].display_name])
	_items.text = "Items: " + ("empty" if parts.is_empty() else "  ".join(parts))
