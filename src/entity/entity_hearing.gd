class_name EntityHearing
extends Node

signal noise_alert(room_id: StringName, floor_id: int, world_position: Vector3)

@export var alert_threshold: float = 1.0
@export var decay_per_second: float = 0.3
# Multiplier for noise on the same floor but in a different room.
@export_range(0.0, 1.0) var other_room_falloff: float = 0.7
# Multiplier applied once per floor of distance.
@export_range(0.0, 1.0) var per_floor_falloff: float = 0.5

var meter: float = 0.0

var _location: LocationTracker
var _best_heard: float = 0.0
var _noise_room_id: StringName = &""
var _noise_floor_id: int = 0
var _noise_position: Vector3

func _ready() -> void:
	_location = LocationTracker.find_on(get_parent())
	if _location == null:
		push_warning("EntityHearing: parent needs a LocationTracker child.")
	NoiseManager.noise_emitted.connect(_on_noise_emitted)

func _physics_process(delta: float) -> void:
	meter = maxf(meter - decay_per_second * delta, 0.0)
	_best_heard = maxf(_best_heard - decay_per_second * delta, 0.0)

## 0..1, for a heartbeat or tension effect if Julianna wants one.
func get_alert_ratio() -> float:
	return clampf(meter / alert_threshold, 0.0, 1.0)

func _on_noise_emitted(
	_noise_type: StringName,
	loudness: float,
	room_id: StringName,
	floor_id: int,
	world_position: Vector3
) -> void:
	if _location == null:
		return
	var heard := _heard_loudness(loudness, room_id, floor_id)
	if heard <= 0.0:
		return
	meter += heard
	# Remember where the loudest recent noise came from.
	if heard >= _best_heard:
		_best_heard = heard
		_noise_room_id = room_id
		_noise_floor_id = floor_id
		_noise_position = world_position
	if meter >= alert_threshold:
		meter = 0.0
		_best_heard = 0.0
		noise_alert.emit(_noise_room_id, _noise_floor_id, _noise_position)

func _heard_loudness(loudness: float, room_id: StringName, floor_id: int) -> float:
	var floors_apart := absi(floor_id - _location.floor_id)
	if floors_apart > 0:
		return loudness * pow(per_floor_falloff, floors_apart)
	if room_id != _location.room_id:
		return loudness * other_room_falloff
	return loudness
