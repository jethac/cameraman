@tool
class_name CameramanThirdPersonAim
## PRE and FINALIZE-stage extension that aims a third-person camera toward a collision-tested
## point.
extends CameramanExtension

## Physics layers tested when finding the third-person aim point.
@export_flags_3d_physics var aim_collision_mask: int = 1
## Maximum aim ray distance in meters.
@export var aim_distance: float = 100.0
## Removes impulse and noise corrections while calculating aim direction.
@export var noise_cancellation: bool = false
## Bodies in this group are skipped by the aim ray.
@export var ignore_group: StringName
## Additional groups skipped by the aim ray.
@export var ignore_groups: Array[StringName] = []

var aim_target: Vector3 = Vector3.ZERO

func pre_pipeline_mutate_camera_state(
	camera: Node,
	state: CameramanCameraState,
	_delta: float
) -> void:
	var node: Node3D = camera as Node3D
	if node == null or node.get_world_3d() == null:
		return
	var start: Vector3 = state.raw_position
	var end: Vector3 = start + state.raw_orientation * Vector3.FORWARD * aim_distance
	var space: PhysicsDirectSpaceState3D = node.get_world_3d().direct_space_state
	var excluded: Array[RID] = []
	var hit: Dictionary = {}
	for _index in 32:
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, end)
		query.collision_mask = aim_collision_mask
		query.exclude = excluded
		hit = space.intersect_ray(query)
		if hit.is_empty():
			break
		var collider: Node = hit.get("collider") as Node
		if collider == null or not _is_ignored(collider):
			break
		if collider is CollisionObject3D:
			excluded.append((collider as CollisionObject3D).get_rid())
		else:
			break
	aim_target = hit["position"] as Vector3 if not hit.is_empty() else end
	state.reference_look_at = aim_target
	if noise_cancellation:
		state.orientation_correction = Quaternion.IDENTITY

func post_pipeline_stage_callback(
	_camera: Node,
	stage: CameramanCore.Stage,
	state: CameramanCameraState,
	_delta: float
) -> void:
	if noise_cancellation and stage == CameramanCore.Stage.NOISE:
		state.orientation_correction = Quaternion.IDENTITY

func _is_ignored(collider: Node) -> bool:
	if not ignore_group.is_empty() and collider.is_in_group(ignore_group):
		return true
	for group_name in ignore_groups:
		if collider.is_in_group(group_name):
			return true
	return false
