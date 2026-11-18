## Put this on the ROOT Control of a pause, game over or win screen (full rect, inside a CanvasLayer).
## One script for all three: pick which GameState state shows it in "show_on_state".
## It hides itself otherwise and listens to GameState.state_changed, so nothing else
## needs to know it exists. Buttons are optional Inspector slots; leave one empty if the
## screen doesn't have it (a win screen has no Resume, a pause screen has no Restart).
class_name StateScreen
extends Control

signal screen_shown
signal screen_hidden

@export_enum("PAUSED", "GAME_OVER", "WIN") var show_on_state: String = "GAME_OVER"
## Wait this long before appearing. 0.8 on the game over screen lets the camera shake play first.
@export var show_delay: float = 0.0
@export var fade_in_time: float = 0.4
@export var resume_button: BaseButton
@export var restart_button: BaseButton
@export var menu_button: BaseButton
## Scene the menu button goes to (the main menu).
@export_file("*.tscn") var menu_scene: String = ""

var _token: int = 0

func _ready() -> void:
	# Must keep running while the tree is paused, or the buttons would never respond.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if resume_button:
		resume_button.pressed.connect(GameState.resume_game)
	if restart_button:
		restart_button.pressed.connect(GameState.restart)
	if menu_button:
		# Same rule as the main menu: no valid scene means the button is disabled.
		if menu_scene == "" or not ResourceLoader.exists(menu_scene):
			menu_button.disabled = true
		else:
			menu_button.pressed.connect(_on_menu_pressed)
	GameState.state_changed.connect(_on_game_state_changed)
	_apply_state(GameState.current)

func _on_game_state_changed(_previous: GameState.State, new_state: GameState.State) -> void:
	_apply_state(new_state)

func _apply_state(state: GameState.State) -> void:
	if GameState.State.keys()[state] == show_on_state:
		_show_screen()
	else:
		_hide_screen()

func _show_screen() -> void:
	# The token cancels a pending delayed show if the state changes again first.
	_token += 1
	var my_token := _token
	if show_delay > 0.0:
		await get_tree().create_timer(show_delay).timeout
		if my_token != _token:
			return
	visible = true
	if fade_in_time > 0.0:
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, fade_in_time)
	else:
		modulate.a = 1.0
	for button in [resume_button, restart_button, menu_button]:
		if button != null and not button.disabled:
			button.grab_focus()
			break
	screen_shown.emit()

func _hide_screen() -> void:
	_token += 1
	if visible:
		visible = false
		screen_hidden.emit()

func _on_menu_pressed() -> void:
	GameState.go_to_menu(menu_scene)
