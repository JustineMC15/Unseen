class_name AIStateMachine
extends Node

signal state_changed(previous_state: String, new_state: String)

## Node name of the state to start in, e.g. "Patrol".
@export var initial_state_name: String = "Patrol"

var _states: Dictionary = {}          # String -> AIState
var current_state: AIState
var current_state_name: String = ""

func _ready() -> void:
	var owner_entity := get_parent() as AIEntity
	for child in get_children():
		if child is AIState:
			_states[child.name] = child
			child.entity = owner_entity
			child.transition_requested.connect(_change_state)
	_change_state(initial_state_name)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func notify_gaze(is_watched: bool, watched_duration: float, delta: float) -> void:
	if current_state:
		current_state.on_gaze_changed(is_watched, watched_duration, delta)

func notify_perception(can_see_player: bool, delta: float) -> void:
	if current_state:
		current_state.on_perception_updated(can_see_player, delta)

func force_transition(state_name: String) -> void:
	_change_state(state_name)

func _change_state(state_name: String) -> void:
	if not _states.has(state_name):
		push_warning("AIStateMachine: no state named '%s'" % state_name)
		return
	if current_state and current_state.name == state_name:
		return
	var previous_name := current_state_name
	if current_state:
		current_state.exit()
	current_state = _states[state_name]
	current_state_name = state_name
	current_state.enter()
	state_changed.emit(previous_name, state_name)
