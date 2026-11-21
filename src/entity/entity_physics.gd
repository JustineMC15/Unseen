class_name EntityPhysics
extends Node

## After moving the entity instantly (teleport, ScareTrigger), call reset_physics()
## so the hair does not whip across the screen.

@export var skeleton: Skeleton3D
@export var bone_prefix: String = "phy_"
@export var physics_enabled: bool = true:
	set(value):
		physics_enabled = value
		if _simulator:
			_simulator.active = value

## TUNING GUIDE
##  - stiffness: how hard a piece snaps back to its normal pose. Higher = less floppy.
##  - drag: how fast swinging dies out. Higher = more damped, BUT it also makes pieces
##    trail behind permanently while the entity keeps walking (the "cape" look). Keep it low.
##  - gravity: pull downward. Keep it low or the pieces sag.

@export_group("Hair")
@export_range(0.0, 10.0, 0.01, "or_greater") var hair_stiffness: float = 5.0
@export_range(0.0, 1.0, 0.01) var hair_drag: float = 0.1
@export_range(0.0, 2.0, 0.01) var hair_gravity: float = 0.2
@export var hair_radius: float = 0.03

@export_group("Skirt")
@export_range(0.0, 10.0, 0.01, "or_greater") var skirt_stiffness: float = 6.0
@export_range(0.0, 1.0, 0.01) var skirt_drag: float = 0.15
@export_range(0.0, 2.0, 0.01) var skirt_gravity: float = 0.2
@export var skirt_radius: float = 0.05

@export_group("Blouse")
@export_range(0.0, 10.0, 0.01, "or_greater") var blouse_stiffness: float = 8.0
@export_range(0.0, 1.0, 0.01) var blouse_drag: float = 0.2
@export_range(0.0, 2.0, 0.01) var blouse_gravity: float = 0.1
@export var blouse_radius: float = 0.02

@export_group("Collar")
@export_range(0.0, 10.0, 0.01, "or_greater") var collar_stiffness: float = 8.0
@export_range(0.0, 1.0, 0.01) var collar_drag: float = 0.2
@export_range(0.0, 2.0, 0.01) var collar_gravity: float = 0.1
@export var collar_radius: float = 0.01

## Optional. If you type a bone name here (for example "Pelvis"), the entity's own
## movement is ignored and the hair and skirt stop reacting to walking, stopping and
## turning. Leave empty for the normal swing.
@export var center_bone: String = ""

## How far past the last bone of a chain the simulated tip extends (metres).
@export var end_bone_length: float = 0.2

var _simulator: SpringBoneSimulator3D


func _ready() -> void:
	# Deferred so the model's scene is fully built before we look inside it.
	_setup.call_deferred()


func reset_physics() -> void:
	if _simulator:
		_simulator.reset()


func _setup() -> void:
	var skel := skeleton
	if skel == null:
		skel = _find_skeleton()
	if skel == null:
		push_warning("EntityPhysics: no Skeleton3D found, physics skipped.")
		return

	var chains := _collect_chains(skel)
	if chains.is_empty():
		push_warning("EntityPhysics: no '%s' bones found. Did the new .glb get exported?" % bone_prefix)
		return

	_simulator = SpringBoneSimulator3D.new()
	_simulator.name = "SpringBoneSimulator3D"
	skel.add_child(_simulator)
	_simulator.setting_count = chains.size()
	_simulator.active = physics_enabled

	for i in chains.size():
		var chain: PackedStringArray = chains[i]
		var group := chain[0].trim_prefix(bone_prefix).get_slice("_", 0)
		var p := _profile(group)
		_simulator.set_root_bone_name(i, chain[0])
		_simulator.set_end_bone_name(i, chain[chain.size() - 1])
		# The last bone has no child, so extend it to give it a tip to simulate.
		_simulator.set_extend_end_bone(i, true)
		_simulator.set_end_bone_direction(i, SpringBoneSimulator3D.BONE_DIRECTION_FROM_PARENT)
		_simulator.set_end_bone_length(i, end_bone_length)
		_simulator.set_radius(i, p.radius)
		_simulator.set_stiffness(i, p.stiffness)
		_simulator.set_drag(i, p.drag)
		_simulator.set_gravity(i, p.gravity)
		_simulator.set_gravity_direction(i, Vector3.DOWN)
		if center_bone != "" and skel.find_bone(center_bone) != -1:
			_simulator.set_center_from(i, SpringBoneSimulator3D.CENTER_FROM_BONE)
			_simulator.set_center_bone_name(i, center_bone)


func _find_skeleton() -> Skeleton3D:
	# Search from the parent so a sibling model node is found too.
	var start: Node = get_parent() if get_parent() else self
	var found := start.find_children("*", "Skeleton3D", true, false)
	return found[0] as Skeleton3D if not found.is_empty() else null


## Returns one PackedStringArray per chain, root bone first.
func _collect_chains(skel: Skeleton3D) -> Array[PackedStringArray]:
	var chains: Array[PackedStringArray] = []
	for bone in skel.get_bone_count():
		if not _is_phy(skel, bone):
			continue
		var parent := skel.get_bone_parent(bone)
		if parent != -1 and _is_phy(skel, parent):
			continue  # not a chain root
		var chain := PackedStringArray([skel.get_bone_name(bone)])
		var current := bone
		while true:
			var next := -1
			for child in skel.get_bone_children(current):
				if _is_phy(skel, child):
					next = child
					break
			if next == -1:
				break
			chain.append(skel.get_bone_name(next))
			current = next
		chains.append(chain)
	return chains


func _is_phy(skel: Skeleton3D, bone: int) -> bool:
	return skel.get_bone_name(bone).begins_with(bone_prefix)


func _profile(group: String) -> Dictionary:
	match group:
		"skirt":
			return {"stiffness": skirt_stiffness, "drag": skirt_drag, "gravity": skirt_gravity, "radius": skirt_radius}
		"blouse":
			return {"stiffness": blouse_stiffness, "drag": blouse_drag, "gravity": blouse_gravity, "radius": blouse_radius}
		"collar":
			return {"stiffness": collar_stiffness, "drag": collar_drag, "gravity": collar_gravity, "radius": collar_radius}
		_:
			return {"stiffness": hair_stiffness, "drag": hair_drag, "gravity": hair_gravity, "radius": hair_radius}
