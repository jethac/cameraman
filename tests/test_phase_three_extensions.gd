extends GutTest

func test_follow_zoom_uses_analytic_fov() -> void:
	var extension: CameramanFollowZoom = CameramanFollowZoom.new()
	extension.width = 10.0
	extension.damping = 0.0
	var state: CameramanCameraState = CameramanCameraState.create_default()
	state.raw_position = Vector3(0.0, 0.0, 10.0)
	state.reference_look_at = Vector3.ZERO
	var camera: Node = Node.new()
	add_child_autofree(camera)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, state, 0.1)
	assert_almost_eq(state.lens.fov_degrees, rad_to_deg(2.0 * atan(0.5)), 0.01)

func test_impulse_event_expires_and_filters_channels() -> void:
	var definition: CameramanImpulseDefinition = CameramanImpulseDefinition.new()
	definition.impulse_channel = 2
	definition.impulse_duration = 1.0
	CameramanCore.current_time_override = 0.0
	var event: CameramanImpulseEvent = definition.create_event(Vector3.ONE, Vector3.ZERO)
	var manager: CameramanImpulseManager = CameramanImpulseManager.new()
	manager.add_impulse_event(event)
	assert_almost_eq((manager.get_impulse_at(Vector3.ZERO, false, 1)[0] as Vector3).length(), 0.0, 0.001)
	assert_gt((manager.get_impulse_at(Vector3.ZERO, false, 2)[0] as Vector3).length(), 0.0)
	CameramanCore.current_time_override = 2.0
	assert_almost_eq((manager.get_impulse_at(Vector3.ZERO, false, 2)[0] as Vector3).length(), 0.0, 0.001)
	CameramanCore.current_time_override = -1.0

func test_target_group_average_and_center() -> void:
	var group: CameramanTargetGroup = CameramanTargetGroup.new()
	var first: Node3D = Node3D.new()
	var second: Node3D = Node3D.new()
	first.position = Vector3.ZERO
	second.position = Vector3(10.0, 0.0, 0.0)
	group.add_child(first)
	group.add_child(second)
	add_child_autofree(group)
	group.add_member(first)
	group.add_member(second)
	group.position_mode = CameramanTargetGroup.PositionMode.GROUP_AVERAGE
	assert_almost_eq(group.get_sphere()[0] as Vector3, Vector3(5.0, 0.0, 0.0), Vector3.ONE * 0.001)
	group.position_mode = CameramanTargetGroup.PositionMode.GROUP_CENTER
	assert_almost_eq(group.get_sphere()[0] as Vector3, Vector3(5.0, 0.0, 0.0), Vector3.ONE * 0.001)
	assert_almost_eq(float(group.get_sphere()[1]), 5.0, 0.001)

func test_recomposer_applies_tilt_at_finalize() -> void:
	var extension: CameramanRecomposer = CameramanRecomposer.new()
	extension.tilt = 20.0
	var state: CameramanCameraState = CameramanCameraState.create_default()
	var camera: Node = Node.new()
	add_child_autofree(camera)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.FINALIZE, state, 0.1)
	var expected: Quaternion = Quaternion(Vector3.RIGHT, deg_to_rad(20.0))
	var dot: float = absf(
		state.raw_orientation.x * expected.x
		+ state.raw_orientation.y * expected.y
		+ state.raw_orientation.z * expected.z
		+ state.raw_orientation.w * expected.w
	)
	assert_almost_eq(dot, 1.0, 0.001)
