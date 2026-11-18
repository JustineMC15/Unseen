## Put this on a Control inside the HUD CanvasLayer. Replaces the prompt and feedback
## part of debug_hud.gd. It only listens to the Interactor's signals; the Interactor
## doesn't know the HUD exists.
## Assign the two Labels in the Inspector. "interactor" is optional: if empty, it is
## found on the node in group "player".
class_name InteractionHud
extends Control

@export var interactor: Interactor
## Shows the prompt, e.g. "[E] Open". Hidden whenever the prompt is empty.
@export var prompt_label: Label
## One-off messages like "It's locked." or "Inventory full."
@export var feedback_label: Label
## %s becomes the prompt text from the Interactor.
@export var prompt_format: String = "[E] %s"
@export var feedback_time: float = 2.0

var _feedback_tween: Tween

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
	if feedback_label:
		feedback_label.visible = false
	if interactor == null:
		# Wait a frame so the Player has joined the "player" group.
		await get_tree().process_frame
		interactor = _find_interactor()
	if interactor == null:
		push_warning("InteractionHud: no Interactor assigned and none found under the player.")
		return
	interactor.prompt_changed.connect(_on_prompt_changed)
	interactor.feedback.connect(_on_feedback)

func _find_interactor() -> Interactor:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return null
	for child in player.get_children():
		if child is Interactor:
			return child as Interactor
	return null

func _on_prompt_changed(text: String) -> void:
	if prompt_label == null:
		return
	prompt_label.visible = text != ""
	prompt_label.text = prompt_format % text if text != "" else ""

func _on_feedback(text: String) -> void:
	if feedback_label == null:
		return
	feedback_label.text = text
	feedback_label.visible = true
	if _feedback_tween:
		_feedback_tween.kill()
	_feedback_tween = create_tween()
	_feedback_tween.tween_interval(feedback_time)
	_feedback_tween.tween_callback(func() -> void: feedback_label.visible = false)
