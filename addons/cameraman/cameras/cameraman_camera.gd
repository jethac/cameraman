class_name CameramanCamera
extends CameramanVirtualCameraBase

@export var tracking_target: Node3D
@export var use_separate_look_at: bool = false
@export var look_at_target: Node3D
@export var lens: CameramanLens

func _init() -> void:
	lens = CameramanLens.new()

func get_follow() -> Node3D:
	return tracking_target if tracking_target != null else super.get_follow()

func get_look_at() -> Node3D:
	if use_separate_look_at and look_at_target != null:
		return look_at_target
	return get_follow()

func get_component(stage_value: CameramanCore.Stage) -> CameramanComponent:
	var result: CameramanComponent
	for child in get_children():
		var component: CameramanComponent = child as CameramanComponent
		if component != null and component.stage() == stage_value:
			result = component
	return result

func internal_update_state(world_up: Vector3, delta: float) -> void:
	var state: CameramanCameraState = CameramanCameraState.create_default(world_up)
	state.lens = lens.duplicate() as CameramanLens
	state.raw_position = global_position
	state.raw_orientation = global_basis.get_rotation_quaternion()
	state.blend_hint = blend_hint
	var target: Node3D = get_look_at()
	if target is CameramanTargetGroup:
		var sphere: Array[Variant] = (target as CameramanTargetGroup).get_sphere()
		state.reference_look_at = sphere[0] as Vector3
	elif target is CameramanVirtualCameraBase:
		state.reference_look_at = (target as CameramanVirtualCameraBase).get_state().get_final_position()
	elif target != null:
		state.reference_look_at = target.global_position
	for extension in get_extensions():
		extension.pre_pipeline_mutate_camera_state(self, state, delta)
	var components: Array[CameramanComponent] = _get_components_sorted()
	for component in components:
		component.pre_pipeline_mutate_camera_state(state, delta)
	for stage_value in [
		CameramanCore.Stage.BODY,
		CameramanCore.Stage.AIM,
		CameramanCore.Stage.NOISE
	]:
		for component in components:
			if component.stage() == stage_value and component.is_valid():
				component.mutate_camera_state(state, delta)
				invoke_post_pipeline_stage_callback(stage_value, state, delta)
	for component in components:
		if component.stage() == CameramanCore.Stage.BODY and component.body_applies_after_aim():
			component.mutate_camera_state(state, delta)
			invoke_post_pipeline_stage_callback(CameramanCore.Stage.BODY, state, delta)
	invoke_post_pipeline_stage_callback(CameramanCore.Stage.FINALIZE, state, delta)
	_state = state
	global_position = state.raw_position
	global_basis = Basis(state.raw_orientation)
	previous_state_is_valid = true

func _get_components_sorted() -> Array[CameramanComponent]:
	var result: Array[CameramanComponent] = _get_components()
	result.sort_custom(func(a: CameramanComponent, b: CameramanComponent) -> bool:
		return a.stage() < b.stage()
	)
	return result
