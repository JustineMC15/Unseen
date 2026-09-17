extends Node

signal gaze_started(target: Node3D)
signal gaze_ended(target: Node3D)

var _watched: Dictionary = {}   # Node3D -> float (seconds held)

func report(target: Node3D, is_watching: bool, delta: float) -> void:
	if is_watching:
		if not _watched.has(target):
			_watched[target] = 0.0
			gaze_started.emit(target)
		_watched[target] += delta
	elif _watched.has(target):
		_watched.erase(target)
		gaze_ended.emit(target)

func is_watched(target: Node3D) -> bool:
	return _watched.has(target)

func get_watched_duration(target: Node3D) -> float:
	return _watched.get(target, 0.0)
