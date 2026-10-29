extends Node
## Autoload as "GameState". Owns the high-level state of the run.
## Other systems listen to state_changed instead of polling.

enum State { MENU, PLAYING, PAUSED, GAME_OVER, WIN }

signal state_changed(previous: State, new_state: State)

## Defaults to PLAYING so any scene can be run directly with F6 for testing.
## The main menu scene should call go_to_menu() / set MENU when it loads.
var current: State = State.PLAYING

func _ready() -> void:
	# Must keep running while the tree is paused, or it could never unpause it.
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if current == State.PLAYING:
			pause_game()
		elif current == State.PAUSED:
			resume_game()

func is_playing() -> bool:
	return current == State.PLAYING

## Pass a scene path to load it first (e.g. from the main menu's Start button).
func start_game(scene_path: String = "") -> void:
	_set_state(State.PLAYING)
	if scene_path != "":
		get_tree().change_scene_to_file(scene_path)

func pause_game() -> void:
	if current == State.PLAYING:
		_set_state(State.PAUSED)

func resume_game() -> void:
	if current == State.PAUSED:
		_set_state(State.PLAYING)

func game_over() -> void:
	if current == State.PLAYING:
		_set_state(State.GAME_OVER)

func win() -> void:
	if current == State.PLAYING:
		_set_state(State.WIN)

func restart() -> void:
	_set_state(State.PLAYING)
	get_tree().reload_current_scene()

func go_to_menu(scene_path: String) -> void:
	_set_state(State.MENU)
	get_tree().change_scene_to_file(scene_path)

func _set_state(new_state: State) -> void:
	if new_state == current:
		return
	var previous := current
	current = new_state
	get_tree().paused = new_state in [State.PAUSED, State.GAME_OVER, State.WIN]
	Input.mouse_mode = (
		Input.MOUSE_MODE_CAPTURED if new_state == State.PLAYING
		else Input.MOUSE_MODE_VISIBLE
	)
	state_changed.emit(previous, new_state)
