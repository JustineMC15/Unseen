extends Control

@export_file("*.tscn") var back_scene: String = "res://user_interface/main_menu/main_menu.tscn"

@onready var master_slider: HSlider = $SettingsPanel/SettingsRows/MasterRow/MasterSlider
@onready var music_slider: HSlider = $SettingsPanel/SettingsRows/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $SettingsPanel/SettingsRows/SfxRow/SfxSlider

@onready var master_value: Label = $SettingsPanel/SettingsRows/MasterRow/MasterValue
@onready var music_value: Label = $SettingsPanel/SettingsRows/MusicRow/MusicValue
@onready var sfx_value: Label = $SettingsPanel/SettingsRows/SfxRow/SfxValue

@onready var back_button: Button = find_child("BackButton", true, false)


func _ready() -> void:
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

	back_button.pressed.connect(_on_back_pressed)

	_update_volume_labels()


func _on_master_changed(value: float) -> void:
	master_value.text = str(int(value)) + "%"


func _on_music_changed(value: float) -> void:
	music_value.text = str(int(value)) + "%"


func _on_sfx_changed(value: float) -> void:
	sfx_value.text = str(int(value)) + "%"


func _update_volume_labels() -> void:
	master_value.text = str(int(master_slider.value)) + "%"
	music_value.text = str(int(music_slider.value)) + "%"
	sfx_value.text = str(int(sfx_slider.value)) + "%"


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(back_scene)
