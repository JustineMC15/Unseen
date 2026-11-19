# To Randy: Attach this to a control node inside the screens
## Put this on a Control inside the screens CanvasLayer (layer 60, full rect).
## Layout: "slots_container" has one Button per save slot (4), slot 1 first.
## Hidden until the SaveItemController asks for it (the player used a rosary).
## While open: the tree is paused (so the entity can't catch the player), the mouse
## is visible, and Esc cancels instead of opening the pause screen.
class_name SaveSlotPicker
extends Control

## Optional. If empty, it is found through the "save_item_controller" group.
@export var controller: SaveItemController
@export var slots_container: Control
@export var cancel_button: BaseButton

var _buttons: Array[Button] = []

func _ready() -> void:
	# Must keep running while the tree is paused, or the buttons would never respond.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if slots_container == null:
		push_warning("SaveSlotPicker: assign 'slots_container' in the Inspector.")
		return
	for child in slots_container.get_children():
		var button := child as Button
		if button == null or _buttons.size() >= SaveStore.SLOT_COUNT:
			continue
		_buttons.append(button)
		button.pressed.connect(_on_slot_pressed.bind(_buttons.size() - 1))
	if cancel_button:
		cancel_button.pressed.connect(_cancel)
	if controller == null:
		# Wait a frame so the Player's SaveItemController has joined its group.
		await get_tree().process_frame
		controller = get_tree().get_first_node_in_group("save_item_controller") as SaveItemController
	if controller == null:
		push_warning("SaveSlotPicker: no SaveItemController assigned or found.")
		return
	controller.picker_requested.connect(_open)

# _input runs before GameState's _unhandled_input, so handling Esc here
# stops it from also opening the pause screen.
func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cancel()

func _open() -> void:
	for i in _buttons.size():
		_buttons[i].text = SaveStore.get_slot_label(i)
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not _buttons.is_empty():
		_buttons[0].grab_focus()

func _close() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_slot_pressed(slot: int) -> void:
	_close()
	controller.confirm(slot)

func _cancel() -> void:
	_close()
	controller.cancel()
