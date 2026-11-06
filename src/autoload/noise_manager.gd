extends Node

signal noise_emitted(
	noise_type: StringName,
	loudness: float,
	room_id: StringName,
	floor_id: int,
	world_position: Vector3
)

func emit_noise(
	noise_type: StringName,
	loudness: float,
	room_id: StringName,
	floor_id: int,
	world_position: Vector3
) -> void:
	noise_emitted.emit(noise_type, loudness, room_id, floor_id, world_position)
