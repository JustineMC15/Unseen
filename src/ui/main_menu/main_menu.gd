extends Control

@export var start_button: Button
@export var load_button: Button
@export var settings_button: Button
@export var quit_button: Button

@export_file("*.tscn") var start_scene: String = ""
@export_file("*.tscn") var load_scene: String = ""
@export_file("*.tscn") var settings_scene: String = ""

func _ready() -> void:
	GameState.enter_menu()

	_bind(start_button, _on_start_pressed)
	_bind(load_button, _on_load_pressed)
	_bind(settings_button, _on_settings_pressed)
	_bind(quit_button, _on_quit_pressed)

	_disable_if_missing(start_button, start_scene)
	_disable_if_missing(load_button, load_scene)
	_disable_if_missing(settings_button, settings_scene)

func _bind(button: Button, handler: Callable) -> void:
	if button == null:
		push_warning("MainMenu: a button slot is empty in the Inspector.")
		return
	button.pressed.connect(handler)

func _disable_if_missing(button: Button, scene_path: String) -> void:
	if button != null:
		button.disabled = not ResourceLoader.exists(scene_path)

func _open(scene_path: String) -> bool:
	if not ResourceLoader.exists(scene_path):
		push_warning("MainMenu: scene not found: '%s'" % scene_path)
		return false
	get_tree().change_scene_to_file(scene_path)
	return true

func _on_start_pressed() -> void:
	# Only flip GameState to PLAYING if the game scene is really going to load.
	if _open(start_scene):
		GameState.start_game()

func _on_load_pressed() -> void:
	_open(load_scene)

func _on_settings_pressed() -> void:
	_open(settings_scene)

func _on_quit_pressed() -> void:
	get_tree().quit()
