## Child of Player. Every physics frame it casts a ray from the camera,
## finds the Interactable being looked at, and reports it to the HUD.
class_name Interactor
extends Node

## The Interactable under the crosshair, or null.
signal focus_changed(target: Interactable)
## Text for the prompt. Empty string means hide the prompt.
signal prompt_changed(text: String)
## One-off messages like "It's locked." or "Inventory full."
signal feedback(text: String)

@export var camera: Camera3D
@export var inventory: Inventory
@export var reach: float = 2.5
@export var interact_action: StringName = &"interact"

var focused: Interactable
var _prompt: String = ""

func _ready() -> void:
	var player := get_parent()
	if camera == null:
		camera = player.get_node_or_null("Head/Camera3D") as Camera3D
	if inventory == null:
		inventory = player.get_node_or_null("Inventory") as Inventory
	if camera == null or inventory == null:
		push_warning("Interactor: needs a Head/Camera3D and a node named 'Inventory' under Player.")
	GameState.state_changed.connect(_on_game_state_changed)

func _physics_process(_delta: float) -> void:
	if camera == null or not GameState.is_playing():
		return
	_set_focus(_find_target())
	_set_prompt(focused.get_prompt(self) if is_instance_valid(focused) else "")

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(interact_action):
		return
	if not GameState.is_playing() or not is_instance_valid(focused):
		return
	focused.interact(self)

func show_feedback(text: String) -> void:
	feedback.emit(text)

func _find_target() -> Interactable:
	var from := camera.global_position
	var to := from + (-camera.global_transform.basis.z) * reach
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_parent()]
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null

	# Walk up from the body that was hit until we find an Interactable.
	var node := hit.collider as Node
	while node != null:
		if node is Interactable:
			return node as Interactable
		node = node.get_parent()
	return null

func _set_focus(target: Interactable) -> void:
	if target == focused:
		return
	focused = target
	focus_changed.emit(focused)

func _set_prompt(text: String) -> void:
	if text == _prompt:
		return
	_prompt = text
	prompt_changed.emit(_prompt)

func _on_game_state_changed(_previous: GameState.State, new_state: GameState.State) -> void:
	if new_state != GameState.State.PLAYING:
		_set_focus(null)
		_set_prompt("")
