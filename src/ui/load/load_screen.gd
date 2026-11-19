# To Randy: Attach this script to the root Control of the load screen scene (full rect). 
# Then drag the scene into "load_scene" on the MainMenu node, which enables the Loads button.
# Layout: "slots_container" has one Button per save slot (4), slot 1 first.
class_name LoadScreen
extends Control

@export_file("*.tscn") var back_scene: String = "res://src/ui/main_menu/main_menu.tscn"
@export var slots_container: Control
@export var back_button: BaseButton

var _buttons: Array[Button] = []

func _ready() -> void:
	if slots_container == null:
		push_warning("LoadScreen: assign 'slots_container' in the Inspector.")
	else:
		for child in slots_container.get_children():
			var button := child as Button
			if button == null or _buttons.size() >= SaveStore.SLOT_COUNT:
				continue
			var slot := _buttons.size()
			_buttons.append(button)
			button.text = SaveStore.get_slot_label(slot)
			button.disabled = SaveStore.read_slot(slot).is_empty()
			button.pressed.connect(_on_slot_pressed.bind(slot))
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _on_slot_pressed(slot: int) -> void:
	# Same two calls as F9 in debug_hud.gd.
	var path := SaveStore.begin_load(slot)
	if path != "":
		GameState.start_game(path)

func _on_back_pressed() -> void:
	if not ResourceLoader.exists(back_scene):
		push_error("LoadScreen: Main Menu scene not found: " + back_scene)
		return
	get_tree().change_scene_to_file(back_scene)
