## Put this on any OmniLight3D or SpotLight3D (not the player's flashlight).
## At random intervals the light flickers in a short burst, then returns to its normal energy.
## It only emits flicker_started; SoundManager hooks that signal on its own to play
## "light_flicker", so this script never references audio.
## It changes light_energy only, so ScareTrigger turning the light off with "visible" still works.
class_name LightFlicker
extends Light3D

signal flicker_started(world_position: Vector3)

## Seconds between bursts (random between the two).
@export var min_gap: float = 4.0
@export var max_gap: float = 12.0
## How many on/off pulses per burst (random between the two).
@export var min_pulses: int = 2
@export var max_pulses: int = 5
## Length of each half pulse, in seconds (random between the two).
@export var min_step: float = 0.03
@export var max_step: float = 0.12
## Energy while "off" as a fraction of normal. 0 is fully dark, 0.2 is a dim buzz.
@export_range(0.0, 1.0) var dim_to: float = 0.05

var _base_energy: float = 1.0
var _gap_left: float = 0.0
var _toggles_left: int = 0
var _step_left: float = 0.0
var _dimmed: bool = false

func _ready() -> void:
	_base_energy = light_energy
	_gap_left = randf_range(min_gap, max_gap)

func _process(delta: float) -> void:
	if _toggles_left > 0 or _step_left > 0.0:
		_step_left -= delta
		if _step_left <= 0.0:
			_advance_burst()
	else:
		_gap_left -= delta
		if _gap_left <= 0.0:
			flicker_now()

## Starts a burst immediately. Anything can call this, e.g. a scripted scare.
func flicker_now() -> void:
	if _toggles_left > 0:
		return
	_toggles_left = randi_range(min_pulses, max_pulses) * 2
	_dimmed = false
	flicker_started.emit(global_position)
	_advance_burst()

func _advance_burst() -> void:
	if _toggles_left <= 0:
		# Burst over: back to normal and wait for the next one.
		light_energy = _base_energy
		_dimmed = false
		_step_left = 0.0
		_gap_left = randf_range(min_gap, max_gap)
		return
	_dimmed = not _dimmed
	light_energy = _base_energy * (dim_to if _dimmed else 1.0)
	_toggles_left -= 1
	_step_left = randf_range(min_step, max_step)
