class_name Concealment
extends Node

signal concealment_broken

## Optional. If empty, it finds the AIEntity on its own.
@export var entity: AIEntity
## Staring at the entity this long (seconds) sends it to Detect, toward the hiding spot.
@export var suspect_time: float = 1.0
## Staring this long breaks cover and sends it to Chase. Keep it higher than suspect_time.
@export var reveal_time: float = 3.0

var is_hidden: bool = false
## Where the current hiding spot is. Set by HidingSpot / Locker.
var hiding_position: Vector3 = Vector3.ZERO

var _stare_timer: float = 0.0
var _suspected: bool = false

## Called by HidingSpot / Locker BEFORE the player is moved, so the entity's
## vision check still sees where the player was standing when they went in.
func enter_hiding_spot(spot_position: Vector3) -> void:
	hiding_position = spot_position
	_stare_timer = 0.0
	_suspected = false
	if _find_entity() and entity.perception.can_see_player():
		# Seen going in: no cover, and the entity commits to a chase toward the spot.
		# Transition first: Chase.enter() resets last_known_player_position to where
		# the player stands right now, so the spot has to be written after it.
		is_hidden = false
		entity.state_machine.force_transition("Chase")
		entity.last_known_player_position = spot_position
		return
	is_hidden = true

func exit_hiding_spot() -> void:
	is_hidden = false
	_stare_timer = 0.0
	_suspected = false

func _physics_process(delta: float) -> void:
	if not is_hidden or not _find_entity():
		return
	if GazeSystem.is_watched(entity):
		_stare_timer += delta
		if not _suspected and _stare_timer >= suspect_time:
			_suspected = true
			entity.last_known_player_position = hiding_position
			# A chasing entity already heads for last_known_player_position; don't downgrade it.
			if entity.state_machine.current_state_name != "Chase":
				entity.state_machine.force_transition("Detect")
		if _stare_timer >= reveal_time:
			_break_concealment()
	else:
		_stare_timer = max(_stare_timer - delta, 0.0)
		if _stare_timer == 0.0:
			_suspected = false

func _break_concealment() -> void:
	is_hidden = false
	_stare_timer = 0.0
	_suspected = false
	concealment_broken.emit()
	entity.state_machine.force_transition("Chase")

func _find_entity() -> bool:
	if entity == null:
		entity = get_tree().get_first_node_in_group("gaze_watchable") as AIEntity
	return entity != null
