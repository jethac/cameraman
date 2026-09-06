@tool
class_name CameramanCameraAttributes
extends CameramanExtension

enum FocusTracking { NONE, LOOK_AT_TARGET, FOLLOW_TARGET, CAMERA, CUSTOM_TARGET }

@export var attributes_path: NodePath
@export var focus_tracking: FocusTracking = FocusTracking.LOOK_AT_TARGET
@export var focus_offset: float = 0.0
@export var focus_damping: float = 0.0
@export var custom_target: Node3D
@export var world_environment: NodePath
@export var dof_near_distance: float = 0.0
@export var dof_far_distance: float = 100.0

var _focus_distance: float = -1.0

func post_pipeline_stage_callback(
	camera: Node,
	stage: CameramanCore.Stage,
	state: CameramanCameraState,
	delta: float
) -> void:
	if stage != CameramanCore.Stage.FINALIZE:
		return
	var target: Node3D = _get_focus_target(camera)
	var desired: float = state.raw_position.distance_to(target.global_position) + focus_offset if target != null else (
		state.raw_position.distance_to(state.reference_look_at) + focus_offset
		if state.has_look_at()
		else state.lens.focus_distance
	)
	if _focus_distance < 0.0 or focus_damping <= 0.0:
		_focus_distance = desired
	else:
		_focus_distance = lerpf(
			_focus_distance,
			desired,
			CameramanDamper.damp(1.0, focus_damping, delta)
		)
	state.lens.focus_distance = _focus_distance
	var attributes: Object = _resolve_attributes(camera)
	if attributes == null:
		return
	attributes.set("dof_blur_near_distance", maxf(_focus_distance + dof_near_distance, 0.0))
	attributes.set("dof_blur_far_distance", maxf(_focus_distance + dof_far_distance, 0.0))
	attributes.set("dof_blur_near_enabled", dof_near_distance > 0.0)
	attributes.set("dof_blur_far_enabled", dof_far_distance > 0.0)
	if attributes is CameraAttributesPhysical and state.lens.physical_properties != null:
		var physical: CameramanLensPhysicalProperties = state.lens.physical_properties
		attributes.set("aperture", physical.aperture)
		attributes.set("shutter_speed", physical.shutter_speed)
		attributes.set("frustum_focus_distance", _focus_distance)
		attributes.set("sensor_size", physical.sensor_size)
		attributes.set("iso", physical.iso)
		attributes.set("blade_count", physical.blade_count)
		attributes.set("curvature", physical.curvature)
		attributes.set("barrel_clipping", physical.barrel_clipping)
		attributes.set("anamorphism", physical.anamorphism)
		attributes.set("lens_shift", physical.lens_shift)
		attributes.set("gate_fit", physical.gate_fit)

func _get_focus_target(camera: Node) -> Node3D:
	match focus_tracking:
		FocusTracking.LOOK_AT_TARGET:
			return camera.call("get_look_at") as Node3D
		FocusTracking.FOLLOW_TARGET:
			return camera.call("get_follow") as Node3D
		FocusTracking.CUSTOM_TARGET:
			return custom_target
		_:
			return null

func _resolve_attributes(camera: Node) -> Object:
	if not attributes_path.is_empty():
		var node: Node = camera.get_node_or_null(attributes_path)
		if node is Camera3D:
			return (node as Camera3D).attributes
		if node is WorldEnvironment and (node as WorldEnvironment).environment != null:
			return (node as WorldEnvironment).environment.camera_attributes
	var camera_3d: Camera3D = camera as Camera3D
	if camera_3d != null:
		return camera_3d.attributes
	var environment: WorldEnvironment = camera.get_node_or_null(world_environment) as WorldEnvironment
	if environment != null and environment.environment != null:
		return environment.environment.camera_attributes
	return null
