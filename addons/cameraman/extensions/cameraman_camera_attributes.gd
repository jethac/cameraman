class_name CameramanCameraAttributes
extends CameramanExtension

enum FocusTracking { NONE, LOOK_AT_TARGET, FOLLOW_TARGET, CAMERA, CUSTOM_TARGET }

@export var focus_tracking: FocusTracking = FocusTracking.LOOK_AT_TARGET
@export var focus_offset: float = 0.0
@export var custom_target: Node3D
@export var world_environment: NodePath
@export var dof_near_distance: float = 0.0
@export var dof_far_distance: float = 100.0

func post_pipeline_stage_callback(
	camera: Node,
	stage: CameramanCore.Stage,
	state: CameramanCameraState,
	_delta: float
) -> void:
	if stage != CameramanCore.Stage.FINALIZE:
		return
	var target: Node3D
	match focus_tracking:
		FocusTracking.LOOK_AT_TARGET:
			target = camera.call("get_look_at") as Node3D
		FocusTracking.FOLLOW_TARGET:
			target = camera.call("get_follow") as Node3D
		FocusTracking.CUSTOM_TARGET:
			target = custom_target
		FocusTracking.CAMERA:
			state.lens.focus_distance = state.lens.focus_distance
			return
		_:
			return
	if target != null:
		state.lens.focus_distance = state.raw_position.distance_to(target.global_position) + focus_offset
	var environment_node: WorldEnvironment = camera.get_node_or_null(world_environment) as WorldEnvironment
	if environment_node == null or environment_node.environment == null:
		return
	var attributes: CameraAttributesPractical = environment_node.environment.camera_attributes as CameraAttributesPractical
	if attributes == null:
		return
	attributes.dof_blur_near_distance = dof_near_distance
	attributes.dof_blur_far_distance = dof_far_distance
	attributes.dof_blur_near_enabled = dof_near_distance > 0.0
	attributes.dof_blur_far_enabled = dof_far_distance > 0.0
