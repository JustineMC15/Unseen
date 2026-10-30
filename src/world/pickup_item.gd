class_name PickupItem
extends Interactable

@export var item: ItemData

func get_prompt(_interactor: Interactor) -> String:
	if item == null or not enabled:
		return ""
	return "Pick up %s" % item.display_name

func _on_interact(interactor: Interactor) -> void:
	if item == null:
		return
	if interactor.inventory.add_item(item):
		queue_free()
	else:
		interactor.show_feedback("Inventory full.")
