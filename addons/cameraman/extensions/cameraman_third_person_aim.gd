class_name CameramanThirdPersonAim
extends CameramanExtension

@export_flags_3d_physics var aim_collision_mask: int = 1
@export var aim_distance: float = 100.0
@export var noise_cancellation: bool = false
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
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, end)
	query.collision_mask = aim_collision_mask
	var hit: Dictionary = node.get_world_3d().direct_space_state.intersect_ray(query)
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
