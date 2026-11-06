extends Button
	
@export var normal_scale := Vector2(1.0, 1.0)
@export var hover_scale := Vector2(1.05, 1.05)

var scale_tween: Tween
var effect_tween: Tween
var static_tween: Tween

var normal_style: StyleBoxFlat
var hover_style: StyleBoxFlat


func _ready() -> void:
	await get_tree().process_frame

	# Keep scaling centered
	pivot_offset = size / 2.0

	# --------------------------------------------------
	# NORMAL BUTTON STYLE
	# --------------------------------------------------

	normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0, 0, 0, 0) # completely transparent
	normal_style.border_width_left = 0
	normal_style.border_width_right = 0
	normal_style.border_width_top = 0
	normal_style.border_width_bottom = 0

	# --------------------------------------------------
	# HOVER BUTTON STYLE
	# --------------------------------------------------

	hover_style = StyleBoxFlat.new()

	# White scary/glowing box
	hover_style.bg_color = Color(1, 1, 1, 0.10)

	# Thin white border
	hover_style.border_width_left = 2
	hover_style.border_width_right = 2
	hover_style.border_width_top = 2
	hover_style.border_width_bottom = 2

	hover_style.border_color = Color(1, 1, 1, 0.75)

	# Slight rounded corners
	hover_style.corner_radius_top_left = 2
	hover_style.corner_radius_top_right = 2
	hover_style.corner_radius_bottom_left = 2
	hover_style.corner_radius_bottom_right = 2

	# Small internal margins
	hover_style.content_margin_left = 15
	hover_style.content_margin_right = 15
	hover_style.content_margin_top = 5
	hover_style.content_margin_bottom = 5

	# --------------------------------------------------
	# APPLY NORMAL STYLE
	# --------------------------------------------------

	add_theme_stylebox_override("normal", normal_style)
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("focus", hover_style)
	add_theme_stylebox_override("pressed", hover_style)

	# --------------------------------------------------
	# HORROR FONT GLOW
	# --------------------------------------------------

	add_theme_color_override(
		"font_color",
		Color(1, 1, 1, 1)
	)

	add_theme_color_override(
		"font_hover_color",
		Color(1, 0.15, 0.15, 1)
	)

	add_theme_color_override(
		"font_focus_color",
		Color(1, 0.15, 0.15, 1)
	)

	add_theme_color_override(
		"font_pressed_color",
		Color(1, 1, 1, 1)
	)

	# Horror/static outline
	add_theme_color_override(
		"font_outline_color",
		Color(1, 1, 1, 0.35)
	)

	add_theme_constant_override(
		"outline_size",
		3
	)

	# Small shadow/glow
	add_theme_color_override(
		"font_shadow_color",
		Color(1, 1, 1, 0.25)
	)

	add_theme_constant_override(
		"shadow_offset_x",
		0
	)

	add_theme_constant_override(
		"shadow_offset_y",
		0
	)

	# --------------------------------------------------
	# SIGNALS
	# --------------------------------------------------

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)

func _on_mouse_entered() -> void:
	_start_horror_effect()


func _on_mouse_exited() -> void:
	_stop_horror_effect()


func _on_focus_entered() -> void:
	_start_horror_effect()


func _on_focus_exited() -> void:
	_stop_horror_effect()


func _start_horror_effect() -> void:

	# Stop old tweens
	if scale_tween:
		scale_tween.kill()

	if effect_tween:
		effect_tween.kill()

	if static_tween:
		static_tween.kill()

	# --------------------------------------------------
	# SCALE
	# --------------------------------------------------

	scale_tween = create_tween()
	scale_tween.set_trans(Tween.TRANS_SINE)
	scale_tween.set_ease(Tween.EASE_OUT)

	scale_tween.tween_property(
		self,
		"scale",
		hover_scale,
		0.12
	)

	# --------------------------------------------------
	# STATIC / FLICKER
	# --------------------------------------------------

	effect_tween = create_tween()
	effect_tween.set_loops()

	effect_tween.tween_property(
		self,
		"modulate:a",
		0.82,
		0.045
	)

	effect_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		0.055
	)

	effect_tween.tween_property(
		self,
		"modulate:a",
		0.90,
		0.035
	)

	effect_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		0.10
	)

	# --------------------------------------------------
	# TINY HORROR GLITCH
	# --------------------------------------------------

	static_tween = create_tween()
	static_tween.set_loops()

	static_tween.tween_property(
		self,
		"rotation",
		deg_to_rad(0.4),
		0.04
	)

	static_tween.tween_property(
		self,
		"rotation",
		deg_to_rad(-0.4),
		0.04
	)

	static_tween.tween_property(
		self,
		"rotation",
		0.0,
		0.06
	)


func _stop_horror_effect() -> void:

	if scale_tween:
		scale_tween.kill()

	if effect_tween:
		effect_tween.kill()

	if static_tween:
		static_tween.kill()

	scale_tween = create_tween()

	scale_tween.set_trans(Tween.TRANS_SINE)
	scale_tween.set_ease(Tween.EASE_OUT)

	scale_tween.tween_property(
		self,
		"scale",
		normal_scale,
		0.12
	)

	modulate.a = 1.0
	rotation = 0.0
