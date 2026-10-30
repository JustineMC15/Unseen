## Base class for anything the player can press E on.
## Put this (or a subclass) on a Node3D that has a physics body somewhere below it.
## The Interactor's ray hits the body, then walks up the tree to find this node.
class_name Interactable
extends Node3D

signal interacted(interactor: Interactor)

## Shown by the HUD, e.g. "Open". The UI adds the "[E]" part.
@export var prompt_text: String = "Interact"
@export var enabled: bool = true

## Empty string means "show no prompt".
func get_prompt(_interactor: Interactor) -> String:
	return prompt_text if enabled else ""

func interact(interactor: Interactor) -> void:
	if not enabled:
		return
	_on_interact(interactor)
	interacted.emit(interactor)

## Override in subclasses.
func _on_interact(_interactor: Interactor) -> void:
	pass
