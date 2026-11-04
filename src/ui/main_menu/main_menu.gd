extends Control

# ==================================================
# SCENES
# ==================================================

@export_file("*.tscn") var play_scene: String = ""
@export_file("*.tscn") var load_scene: String = ""
@export_file("*.tscn") var settings_scene: String = "res://user_interface/settings/settings.tscn"

# ==================================================
# BUTTONS
# ==================================================

@onready var play_button: Button = find_child("PlayButton", true, false)
@onready var load_button: Button = find_child("LoadButton", true, false)
@onready var settings_button: Button = find_child("SettingsButton", true, false)
@onready var quit_button: Button = find_child("QuitButton", true, false)


func _ready() -> void:
	# Connect buttons
	if play_button:
		play_button.pressed.connect(_on_play_pressed)

	if load_button:
		load_button.pressed.connect(_on_load_pressed)

	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)

	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)


# ==================================================
# PLAY
# ==================================================

func _on_play_pressed() -> void:
	if play_scene != "":
		get_tree().change_scene_to_file(play_scene)


# ==================================================
# LOAD
# ==================================================

func _on_load_pressed() -> void:
	if load_scene != "":
		get_tree().change_scene_to_file(load_scene)


# ==================================================
# SETTINGS
# ==================================================

func _on_settings_pressed() -> void:
	if settings_scene != "":
		get_tree().change_scene_to_file(settings_scene)


# ==================================================
# QUIT
# ==================================================

func _on_quit_pressed() -> void:
	get_tree().quit()
