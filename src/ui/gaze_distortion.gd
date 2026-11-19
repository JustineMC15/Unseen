class_name GazeDistortion
extends CanvasLayer

const SHADER: Shader = preload("res://src/ui/effects/gaze_distortion.gdshader")


@export var watchable_group: StringName = &"gaze_watchable"
## Seconds to fade in when the gaze lands / out when it leaves.
## Only the fade; the strength is always the same.
@export var fade_in_time: float = 0.1
@export var fade_out_time: float = 0.25

var _rect: ColorRect
var _material: ShaderMaterial
var _amount: float = 0.0

func _ready() -> void:
	layer = 40   # under StaticOverlay (50), over normal HUD layers
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.visible = false
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_rect.material = _material
	add_child(_rect)
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	var watched := _is_anything_watched()
	var target := 1.0 if watched else 0.0
	var fade_time := fade_in_time if watched else fade_out_time
	_amount = move_toward(_amount, target, delta / maxf(fade_time, 0.001))
	_rect.visible = _amount > 0.001
	_material.set_shader_parameter("amount", _amount)

func _is_anything_watched() -> bool:
	for node in get_tree().get_nodes_in_group(watchable_group):
		var target := node as Node3D
		if target != null and GazeSystem.is_watched(target):
			return true
	return false
