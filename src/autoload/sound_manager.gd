## SOUND IDS (one SoundEntry each; a missing one just stays silent and warns once in Output):
##   Loops:   ambience (bus Ambience), chase_music (bus Music)
##   Player:  footstep_walk, footstep_sprint, flashlight_click, item_pickup
##   Doors:   door_open, door_close, door_locked
##   Entity:  entity_patrol, entity_detect, entity_chase, entity_search, entity_investigate
##            (3D, follows the entity, repeats while it stays in that state)
##   Stings:  chase_sting, game_over, win
##   Lights:  light_flicker (3D, plays when a LightFlicker starts a burst)
extends Node

## Fill these in the Inspector. One SoundEntry per id above.
@export var entries: Array[SoundEntry] = []
@export var ambience_id: StringName = &"ambience"
@export var chase_music_id: StringName = &"chase_music"
@export var chase_sting_id: StringName = &"chase_sting"
@export var fade_time: float = 1.0
@export var entity_voice_height: float = 2.0

var _by_id: Dictionary = {}        # StringName -> SoundEntry
var _last_index: Dictionary = {}   # StringName -> int, last stream used, to avoid repeats
var _warned: Dictionary = {}       # StringName -> true, ids already warned about
var _loops: Dictionary = {}        # StringName -> AudioStreamPlayer
var _voice: AudioStreamPlayer3D
var _voice_id: StringName = &""

func _ready() -> void:
	# Must keep running while the tree is paused so the game over sound can play.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus_name in [&"Music", &"SFX", &"Ambience"]:
		_ensure_bus(bus_name)
	for entry in entries:
		if entry != null and entry.id != &"":
			_by_id[entry.id] = entry
	NoiseManager.noise_emitted.connect(_on_noise_emitted)
	GameState.state_changed.connect(_on_game_state_changed)
	get_tree().node_added.connect(_on_node_added)

# One-shot that isn't tied to a place (stings, UI, game over).
func play(id: StringName) -> void:
	var entry := _get_entry(id)
	if entry == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = _pick_stream(entry)
	player.volume_db = entry.volume_db
	player.pitch_scale = _random_pitch(entry)
	player.bus = StringName(entry.bus)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

# One-shot that comes from a spot in the world (doors, footsteps). Quieter with distance.
func play_at(id: StringName, world_position: Vector3) -> void:
	var entry := _get_entry(id)
	if entry == null:
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = _pick_stream(entry)
	player.volume_db = entry.volume_db
	player.pitch_scale = _random_pitch(entry)
	player.bus = StringName(entry.bus)
	player.max_distance = entry.max_distance
	add_child(player)
	player.global_position = world_position
	player.finished.connect(player.queue_free)
	player.play()

# Starts a looping sound with a fade in. Does nothing if that loop is already running.
func start_loop(id: StringName) -> void:
	if _loops.has(id):
		return
	var entry := _get_entry(id)
	if entry == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = _pick_stream(entry)
	player.bus = StringName(entry.bus)
	player.volume_db = -80.0
	add_child(player)
	# Restarts the sound when it ends, so it loops even if the file's Loop import option is off.
	player.finished.connect(_on_loop_finished.bind(id, player))
	player.play()
	_loops[id] = player
	create_tween().tween_property(player, "volume_db", entry.volume_db, fade_time)

func stop_loop(id: StringName, fade: float = -1.0) -> void:
	if not _loops.has(id):
		return
	var player: AudioStreamPlayer = _loops[id]
	_loops.erase(id)
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -80.0, fade if fade >= 0.0 else fade_time)
	tween.tween_callback(player.queue_free)

func stop_all_loops(fade: float = -1.0) -> void:
	for id in _loops.keys():
		stop_loop(id, fade)

func set_bus_percent(bus_name: StringName, percent: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	var linear := clampf(percent / 100.0, 0.0, 1.0)
	AudioServer.set_bus_mute(index, linear <= 0.0)
	if linear > 0.0:
		AudioServer.set_bus_volume_db(index, linear_to_db(linear))

func get_bus_percent(bus_name: StringName) -> float:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return 100.0
	if AudioServer.is_bus_mute(index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index)) * 100.0

func _on_noise_emitted(
	noise_type: StringName,
	_loudness: float,
	_room_id: StringName,
	_floor_id: int,
	world_position: Vector3
) -> void:
	play_at(noise_type, world_position)

func _on_game_state_changed(_previous: GameState.State, new_state: GameState.State) -> void:
	match new_state:
		GameState.State.PAUSED:
			_set_loops_paused(true)
		GameState.State.PLAYING:
			_set_loops_paused(false)
		GameState.State.GAME_OVER:
			stop_all_loops(0.3)
			play(&"game_over")
		GameState.State.WIN:
			stop_all_loops(2.0)
			play(&"win")
		GameState.State.MENU:
			stop_all_loops(0.5)

func _on_node_added(node: Node) -> void:
	if node is Player:
		start_loop(ambience_id)
	elif node is AIEntity:
		_hook_entity(node as AIEntity)
	elif node is Flashlight:
		(node as Flashlight).toggled.connect(_on_flashlight_toggled)
	elif node is Inventory:
		(node as Inventory).item_added.connect(_on_item_added)
	elif node.has_signal(&"flicker_started"):
		node.connect(&"flicker_started", _on_light_flicker_started)

func _on_flashlight_toggled(_is_on: bool) -> void:
	play(&"flashlight_click")

func _on_light_flicker_started(world_position: Vector3) -> void:
	play_at(&"light_flicker", world_position)

func _on_item_added(_item: ItemData, _slot: int) -> void:
	play(&"item_pickup")

func _on_loop_finished(id: StringName, player: AudioStreamPlayer) -> void:
	# Ignore players that were stopped or replaced.
	if _loops.get(id) != player:
		return
	var entry := _get_entry(id)
	if entry == null:
		return
	player.stream = _pick_stream(entry)
	player.play()

func _hook_entity(entity: AIEntity) -> void:
	await entity.ready
	if entity.state_machine == null:
		return
	_voice = AudioStreamPlayer3D.new()
	_voice.position = Vector3(0.0, entity_voice_height, 0.0)
	_voice.finished.connect(_play_voice)
	entity.add_child(_voice)
	entity.state_machine.state_changed.connect(_on_entity_state_changed)
	_on_entity_state_changed("", entity.state_machine.current_state_name)

func _on_entity_state_changed(_previous: String, new_state: String) -> void:
	if not is_instance_valid(_voice):
		return
	if new_state == "Chase":
		play(chase_sting_id)
		start_loop(chase_music_id)
	else:
		stop_loop(chase_music_id)
	_voice.stop()
	_voice_id = StringName("entity_" + new_state.to_lower())
	_play_voice()

## Plays the current state's voice. Called again when the clip ends, so it repeats while the state lasts.
func _play_voice() -> void:
	if not is_instance_valid(_voice):
		return
	var entry := _get_entry(_voice_id, false)
	if entry == null:
		_voice.stop()
		return
	_voice.stream = _pick_stream(entry)
	_voice.volume_db = entry.volume_db
	_voice.pitch_scale = _random_pitch(entry)
	_voice.bus = StringName(entry.bus)
	_voice.max_distance = entry.max_distance
	_voice.play()

func _get_entry(id: StringName, warn: bool = true) -> SoundEntry:
	var entry: SoundEntry = _by_id.get(id)
	if entry == null or entry.streams.is_empty():
		if warn and not _warned.has(id):
			_warned[id] = true
			push_warning("SoundManager: no sound assigned for '%s'." % id)
		return null
	return entry

func _pick_stream(entry: SoundEntry) -> AudioStream:
	var count := entry.streams.size()
	var index := randi() % count
	if count > 1 and index == _last_index.get(entry.id, -1):
		index = (index + 1 + randi() % (count - 1)) % count
	_last_index[entry.id] = index
	return entry.streams[index]

func _random_pitch(entry: SoundEntry) -> float:
	return 1.0 + randf_range(-entry.pitch_variation, entry.pitch_variation)

func _set_loops_paused(value: bool) -> void:
	for player in _loops.values():
		(player as AudioStreamPlayer).stream_paused = value

func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, &"Master")

# Make sure to connect these for audio of vignette
#entity.detect_started.connect(_detect_sting.play)
#entity.chase_started.connect(_chase_loop.play)
#entity.chase_ended.connect(_chase_loop.stop)
#entity.caught_player.connect(_catch_scream.play)
