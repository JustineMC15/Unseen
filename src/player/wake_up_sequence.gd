class_name WakeUpSequence
extends Node

signal started        # screen is black; start breathing / ambience here
signal eyes_opened    # the first flutter begins
signal finished

const SHADER: Shader = preload("res://src/ui/effects/eyelid_open.gdshader")

@export var enabled: bool = true
## Seconds of black before the eyes start to open.
@export var start_delay: float = 1.0
## Negative looks down.
@export var start_pitch_deg: float = -65.0
## Metres the head starts below its normal height.
@export var head_drop: float = 0.5
## Seconds for the camera to rise to eye level.
@export var camera_time: float = 4.2

var _player: Player
var _layer: CanvasLayer
var _material: ShaderMaterial
var _tween: Tween

func _ready() -> void:
	if not enabled or SaveStore.has_pending():
		return
	_player = get_parent() as Player
	if _player == null:
		push_warning("WakeUpSequence: must be a child of the Player.")
		return
	# Black immediately, so the scene never flashes before the animation starts.
	_build_overlay()
	# The Player's @onready vars (head, camera) are not set until its own _ready has run.
	await get_tree().process_frame
	_play()

func _build_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("open", 0.0)
	_material.set_shader_parameter("blur", 1.0)
	rect.material = _material
	_layer.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _play() -> void:
	var head := _player.head
	var rest_y := head.position.y
	head.rotation.x = deg_to_rad(start_pitch_deg)
	head.position.y = rest_y - head_drop
	_player.freeze_controls()
	started.emit()

	# Eyelids: flutter open, blink, open more, blink, open fully.
	_tween = create_tween()
	_tween.tween_interval(start_delay)
	_tween.tween_callback(eyes_opened.emit)
	_lid(0.30, 0.9, 0.9)
	_lid(0.04, 0.35, 1.0)
	_lid(0.65, 0.8, 0.55)
	_lid(0.12, 0.3, 0.7)
	_lid(1.0, 1.4, 0.0)

	# Camera: starts a moment after the eyes begin to open. Finishing it ends the sequence.
	var delay := start_delay + 0.3
	var cam := create_tween().set_parallel(true)
	cam.tween_property(head, "rotation:x", 0.0, camera_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(delay)
	cam.tween_property(head, "position:y", rest_y, camera_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_delay(delay)
	cam.finished.connect(_finish)

func _lid(open_to: float, time: float, blur_to: float) -> void:
	_tween.tween_property(_material, "shader_parameter/open", open_to, time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.parallel().tween_property(_material, "shader_parameter/blur", blur_to, time)

func _finish() -> void:
	if _tween:
		_tween.kill()
	_layer.queue_free()
	_player.unlock_controls()
	finished.emit()
