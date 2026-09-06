@tool
class_name CameramanThirdPersonAim
## Provides the third person aim camera pipeline extension.
## Key properties include `aim_collision_mask`, `aim_distance`, `noise_cancellation`, and related settings, which
## configure its behavior.
extends CameramanExtension

## Selects the physics layers or camera channels used by aim collision mask.
@export_flags_3d_physics var aim_collision_mask: int = 1
## Sets the aim distance used by this type.
@export var aim_distance: float = 100.0
## Configures the noise cancellation used by this type.
@export var noise_cancellation: bool = false
## Configures the ignore group used by this type.
@export var ignore_group: StringName
## Configures the ignore groups used by this type.
@export var ignore_groups: Array[StringName] = []

var aim_target: Vector3 = Vector3.ZERO

## Applies this extension before the component pipeline runs.
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

## Applies extension behavior after the specified pipeline stage.
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
