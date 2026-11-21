class_name StepClimber
extends Node

# Tallest lip it will climb
@export var max_step_height: float = 0.2
@export var min_step_height: float = 0.03
@export var feet_offset: float = 0.0
# Height above the feet where the ray checks the obstacle's face.
@export var probe_height: float = 0.05
# A face counts as a lip if abs(normal.y) is below this. Ramps are about 0.7-0.9.
@export var max_face_normal_y: float = 0.1
# Minimum forward move when stepping, so the capsule's rounded bottom ends up
# over the lip instead of hanging on its edge.
@export var min_forward: float = 0.1

var _body: CharacterBody3D

static func find_on(node: Node) -> StepClimber:
	if node == null:
		return null
	for child in node.get_children():
		if child is StepClimber:
			return child as StepClimber
	return null

func _ready() -> void:
	_body = get_parent() as CharacterBody3D
	if _body == null:
		push_warning("StepClimber: parent must be a CharacterBody3D.")

func apply(delta: float) -> void:
	if _body == null or not _body.is_on_floor():
		return
	var flat := Vector3(_body.velocity.x, 0.0, _body.velocity.z)
	if flat.length() < 0.1:
		return
	var dir := flat.normalized()
	var motion := flat * delta
	var from := _body.global_transform

	# Only act if this frame's move is actually blocked.
	var hit := KinematicCollision3D.new()
	if not _body.test_move(from, motion, hit):
		return

	# The obstacle must have a near vertical face so it does not work on ramps
	var origin := _body.global_position
	var contact := hit.get_position()
	var to_contact := Vector3(contact.x - origin.x, 0.0, contact.z - origin.z)
	if to_contact.length() < 0.001:
		return
	var ray_from := Vector3(origin.x, origin.y - feet_offset + probe_height, origin.z)
	var ray_to := ray_from + to_contact.normalized() * (to_contact.length() + 0.1)
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to, _body.collision_mask)
	query.exclude = [_body.get_rid()]
	var face := _body.get_world_3d().direct_space_state.intersect_ray(query)
	if face.is_empty() or absf(face.normal.y) > max_face_normal_y:
		return

	# Check for headroom above.
	var up := Vector3.UP * max_step_height
	if _body.test_move(from, up):
		return

	# Clear path at the raised height, else it is a real wall.
	var forward := dir * maxf(motion.length(), min_forward)
	var raised := from.translated(up)
	if _body.test_move(raised, forward):
		return

	# Finds the top of the step and make sure it is walkable.
	var ahead := raised.translated(forward)
	var down := KinematicCollision3D.new()
	if not _body.test_move(ahead, -up, down):
		return
	if down.get_normal().angle_to(Vector3.UP) > _body.floor_max_angle:
		return
	var rise := max_step_height + down.get_travel().y
	if rise < min_step_height:
		return

	# Puts the body on the step.
	_body.global_position = ahead.origin + down.get_travel()
	_body.apply_floor_snap()
