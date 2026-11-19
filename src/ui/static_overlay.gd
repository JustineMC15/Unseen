class_name StaticOverlay
extends CanvasLayer

const DEFAULT_SHADER: Shader = preload("res://src/ui/effects/static_vignette.gdshader")

## Optional. If empty it finds the entity in the "gaze_watchable" group.
@export var entity: AIEntity
## Static strength (0-1) per state node name. Missing states count as 0.
@export var state_intensity: Dictionary = {
	"Patrol": 0.0,
	"Investigate": 0.12,
	"Search": 0.2,
	"Detect": 0.4,
	"Chase": 0.6,
}
## Intensity per second when getting stronger / weaker.
@export var rise_speed: float = 4.0
@export var fall_speed: float = 0.5
## Extra spike the moment Detect / Chase starts, fading at punch_decay per second.
@export var detect_punch: float = 0.3
@export var chase_punch: float = 0.4
@export var punch_decay: float = 2.0
## Max extra static from the entity's hearing meter (rises as it hears noise).
@export var noise_tension: float = 0.2
## Cap while playing, so only a catch reaches total static.
@export var max_before_catch: float = 0.95

@export var go_to_menu_on_game_over: bool = true
@export_file("*.tscn") var menu_scene: String = "res://src/ui/main_menu/main_menu.tscn"
## Seconds to ramp to full static, then to hold it before leaving.
@export var catch_ramp_time: float = 0.3
@export var catch_hold_time: float = 1.2

var _rect: ColorRect
var _material: ShaderMaterial
var _entity: AIEntity
var _level: float = 0.0
var _punch: float = 0.0
var _shown: float = 0.0
var _caught: bool = false
var _caught_time: float = 0.0
var _caught_from: float = 0.0
var _leaving: bool = false

func _ready() -> void:
	# Must keep running while the tree is paused (game over pauses it).
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.visible = false
	_material = ShaderMaterial.new()
	_material.shader = DEFAULT_SHADER
	_rect.material = _material
	add_child(_rect)
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	GameState.state_changed.connect(_on_game_state_changed)
	if entity != null:
		_hook_entity(entity)

func _process(delta: float) -> void:
	if _caught:
		_process_caught(delta)
		return
	if _entity == null:
		var found := get_tree().get_first_node_in_group("gaze_watchable") as AIEntity
		if found != null:
			_hook_entity(found)
	var target := _compute_target()
	var speed := rise_speed if target > _level else fall_speed
	_level = move_toward(_level, target, speed * delta)
	_punch = move_toward(_punch, 0.0, punch_decay * delta)
	_apply(minf(_level + _punch, max_before_catch))

func _compute_target() -> float:
	if _entity == null or not _entity.is_active:
		return 0.0
	var state := _entity.state_machine.current_state_name
	var target: float = state_intensity.get(state, 0.0)
	if _entity.hearing != null:
		target = maxf(target, _entity.hearing.get_alert_ratio() * noise_tension)
	return target

func _process_caught(delta: float) -> void:
	_caught_time += delta
	var ramp := clampf(_caught_time / catch_ramp_time, 0.0, 1.0)
	_apply(lerpf(_caught_from, 1.0, ramp))
	if _leaving or not go_to_menu_on_game_over:
		return
	if _caught_time >= catch_ramp_time + catch_hold_time:
		_leaving = true
		if ResourceLoader.exists(menu_scene):
			GameState.go_to_menu(menu_scene)
		else:
			push_error("StaticOverlay: menu scene not found: " + menu_scene)

func _apply(value: float) -> void:
	_shown = value
	_rect.visible = value > 0.003
	_material.set_shader_parameter("intensity", value)

func _hook_entity(e: AIEntity) -> void:
	_entity = e
	e.detect_started.connect(_on_detect_started)
	e.chase_started.connect(_on_chase_started)

func _on_detect_started() -> void:
	_punch = maxf(_punch, detect_punch)

func _on_chase_started() -> void:
	_punch = maxf(_punch, chase_punch)

func _on_game_state_changed(_previous: GameState.State, new_state: GameState.State) -> void:
	if new_state == GameState.State.GAME_OVER:
		_caught = true
		_caught_time = 0.0
		_caught_from = _shown
	elif new_state == GameState.State.PLAYING:
		_caught = false
		_leaving = false
