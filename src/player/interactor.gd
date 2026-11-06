## Child of Player. Every physics frame it casts a ray from the player's head,
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
## How close the player must be to an Interactable's origin (flat distance, height ignored).
@export var reach: float = 2.5
## The ray is this much longer than reach, so colliders set back from an object's
## visible front (a locker's back wall is 1.2 m behind its front) can still be hit.
## The reach check uses the Interactable's origin, not the hit point.
@export var ray_extra: float = 1.5
## After the ray stops hitting a target, keep it focused this many seconds.
## Stops one missed frame while walking from dropping the prompt or the E press.
@export var focus_grace_time: float = 0.15
@export var interact_action: StringName = &"interact"

var focused: Interactable
var _forced_focus: Interactable
var _prompt: String = ""
var _grace_left: float = 0.0

func _ready() -> void:
	if camera == null or inventory == null:
		push_warning("Interactor: assign 'camera' and 'inventory' in the inspector.")
	GameState.state_changed.connect(_on_game_state_changed)

func _physics_process(delta: float) -> void:
	if camera == null or not GameState.is_playing():
		return
	var target: Interactable = null
	if is_instance_valid(_forced_focus):
		target = _forced_focus
	else:
		target = _find_target()
		if target != null:
			_grace_left = focus_grace_time
		elif is_instance_valid(focused) and _grace_left > 0.0:
			_grace_left -= delta
			target = focused
	_set_focus(target)
	_set_prompt(focused.get_prompt(self) if is_instance_valid(focused) else "")

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(interact_action):
		return
	if not GameState.is_playing() or not is_instance_valid(focused):
		return
	focused.interact(self)

func show_feedback(text: String) -> void:
	feedback.emit(text)

func force_focus(target: Interactable) -> void:
	_forced_focus = target

func release_focus() -> void:
	_forced_focus = null
	_grace_left = 0.0

func _find_target() -> Interactable:
	# The camera bobs while walking; its parent (Head) does not.
	var head := camera.get_parent() as Node3D
	var from: Vector3 = (head if head != null else camera).global_position
	var to := from + (-camera.global_transform.basis.z) * (reach + ray_extra)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_parent()]
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	var node := hit.collider as Node
	while node != null:
		if node is Interactable:
			var found := node as Interactable
			return found if _in_reach(found, from) else null
		node = node.get_parent()
	return null

func _in_reach(target: Interactable, from: Vector3) -> bool:
	var offset := target.global_position - from
	return Vector2(offset.x, offset.z).length() <= reach

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
		_grace_left = 0.0
		_set_focus(null)
		_set_prompt("")
