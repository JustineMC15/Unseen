class_name AIState
extends Node

signal transition_requested(state_name: String)

var entity: AIEntity

func enter() -> void:
	pass

func exit() -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func on_gaze_changed(_is_watched: bool, _watched_duration: float, _delta: float) -> void:
	pass

func on_perception_updated(_can_see_player: bool, _delta: float) -> void:
	pass
