extends GutTest

func test_follow_zoom_uses_analytic_fov() -> void:
	var extension: CameramanFollowZoom = CameramanFollowZoom.new()
	autofree(extension)
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
	autofree(extension)
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

func test_confiner_3d_clamps_box() -> void:
	var camera: Node3D = Node3D.new()
	add_child_autofree(camera)
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "Bounds"
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(4.0, 4.0, 4.0)
	shape.shape = box
	camera.add_child(shape)
	var extension: CameramanConfiner3D = CameramanConfiner3D.new()
	extension.bounding_volume = NodePath("Bounds")
	autofree(extension)
	var state: CameramanCameraState = CameramanCameraState.create_default()
	state.raw_position = Vector3(10.0, 0.0, 0.0)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, state, 0.1)
	assert_almost_eq(state.get_final_position().x, 2.0, 0.001)

func test_confiner_2d_clamps_window() -> void:
	var previous_aspect_ratio: float = CameramanCameraState.aspect_ratio
	CameramanCameraState.aspect_ratio = 1280.0 / 720.0
	var camera: Node = Node.new()
	add_child_autofree(camera)
	var polygon: CollisionPolygon2D = CollisionPolygon2D.new()
	polygon.name = "Bounds"
	polygon.polygon = PackedVector2Array([
		Vector2(0.0, -1000.0), Vector2(4800.0, -1000.0),
		Vector2(4800.0, 2000.0), Vector2(0.0, 2000.0)
	])
	camera.add_child(polygon)
	var extension: CameramanConfiner2D = CameramanConfiner2D.new()
	extension.bounding_shape = NodePath("Bounds")
	autofree(extension)
	var state: CameramanCameraState = CameramanCameraState.create_default()
	state.lens.mode_override = CameramanLens.Mode.ORTHOGRAPHIC
	state.lens.orthographic_size = 360.0
	state.raw_position = Vector3(5000.0, 0.0, 0.0)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, state, 0.1)
	assert_almost_eq(state.get_final_position().x, 4160.0, 0.001)
	assert_almost_eq(state.get_final_position().y, 0.0, 0.001)
	CameramanCameraState.aspect_ratio = previous_aspect_ratio

func test_group_framing_zoom_only_reduces_fov() -> void:
	var camera: CameramanVirtualCameraBase = CameramanVirtualCameraBase.new()
	var group: CameramanTargetGroup = CameramanTargetGroup.new()
	var target: Node3D = Node3D.new()
	target.position = Vector3(0.0, 0.0, -10.0)
	group.add_child(target)
	camera.add_child(group)
	add_child_autofree(camera)
	group.add_member(target)
	camera.set_look_at(group)
	var extension: CameramanGroupFraming = CameramanGroupFraming.new()
	extension.size_adjustment = CameramanGroupFraming.SizeAdjustment.ZOOM_ONLY
	autofree(extension)
	var state: CameramanCameraState = CameramanCameraState.create_default()
	state.raw_position = Vector3.ZERO
	state.raw_orientation = Quaternion.IDENTITY
	var before: float = state.lens.fov_degrees
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, state, 0.1)
	assert_lt(state.lens.fov_degrees, before)

func test_freelook_lens_interpolates_top_middle_bottom() -> void:
	var camera: Node = Node.new()
	add_child_autofree(camera)
	var orbital: CameramanOrbitalFollow = CameramanOrbitalFollow.new()
	camera.add_child(orbital)
	var modifier: CameramanFreeLookModifier = CameramanFreeLookModifier.new()
	autofree(modifier)
	var lens: CameramanFreeLookModifier.LensModifier = CameramanFreeLookModifier.LensModifier.new()
	lens.bottom_value = 0.0
	lens.top_value = 20.0
	modifier.modifier_resources = [lens]
	var state: CameramanCameraState = CameramanCameraState.create_default()
	orbital.vertical_axis.value = orbital.vertical_axis.range.x
	modifier.pre_pipeline_mutate_camera_state(camera, state, 0.1)
	var bottom: float = state.lens.fov_degrees
	orbital.vertical_axis.value = 0.0
	state = CameramanCameraState.create_default()
	modifier.pre_pipeline_mutate_camera_state(camera, state, 0.1)
	var middle: float = state.lens.fov_degrees
	orbital.vertical_axis.value = orbital.vertical_axis.range.y
	state = CameramanCameraState.create_default()
	modifier.pre_pipeline_mutate_camera_state(camera, state, 0.1)
	assert_almost_eq(bottom, 60.0, 0.001)
	assert_almost_eq(middle, 70.0, 0.001)
	assert_almost_eq(state.lens.fov_degrees, 80.0, 0.001)

func test_third_person_aim_falls_back_to_max_distance() -> void:
	var camera: Node3D = Node3D.new()
	add_child_autofree(camera)
	var extension: CameramanThirdPersonAim = CameramanThirdPersonAim.new()
	autofree(extension)
	var state: CameramanCameraState = CameramanCameraState.create_default()
	state.raw_position = Vector3.ZERO
	extension.pre_pipeline_mutate_camera_state(camera, state, 0.1)
	assert_almost_eq(extension.aim_target, Vector3(0.0, 0.0, -100.0), Vector3.ONE * 0.001)

func test_deoccluder_pulls_camera_in_front_of_box() -> void:
	var root: Node3D = Node3D.new()
	var target: Node3D = Node3D.new()
	var camera: CameramanCamera = CameramanCamera.new()
	var obstacle: StaticBody3D = StaticBody3D.new()
	var obstacle_shape: CollisionShape3D = CollisionShape3D.new()
	var obstacle_box: BoxShape3D = BoxShape3D.new()
	obstacle_box.size = Vector3(4.0, 4.0, 0.5)
	obstacle_shape.shape = obstacle_box
	obstacle.add_child(obstacle_shape)
	obstacle.position.z = 5.0
	camera.tracking_target = target
	var extension: CameramanDeoccluder = CameramanDeoccluder.new()
	extension.avoid_obstacles_enabled = true
	camera.add_child(extension)
	root.add_child(target)
	root.add_child(obstacle)
	root.add_child(camera)
	add_child_autofree(root)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var state: CameramanCameraState = CameramanCameraState.create_default()
	state.raw_position = Vector3(0.0, 0.0, 10.0)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, state, 0.1)
	assert_lt(state.get_final_position().z, 10.0)
	assert_lt(state.shot_quality, 0.1)

func test_third_person_aim_uses_hit_point() -> void:
	var root: Node3D = Node3D.new()
	var camera: CameramanCamera = CameramanCamera.new()
	var obstacle: StaticBody3D = StaticBody3D.new()
	var obstacle_shape: CollisionShape3D = CollisionShape3D.new()
	var obstacle_box: BoxShape3D = BoxShape3D.new()
	obstacle_box.size = Vector3(4.0, 4.0, 0.5)
	obstacle_shape.shape = obstacle_box
	obstacle.add_child(obstacle_shape)
	obstacle.position.z = -5.0
	root.add_child(obstacle)
	root.add_child(camera)
	add_child_autofree(root)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var extension: CameramanThirdPersonAim = CameramanThirdPersonAim.new()
	autofree(extension)
	var state: CameramanCameraState = CameramanCameraState.create_default()
	state.raw_position = Vector3.ZERO
	state.raw_orientation = Quaternion.IDENTITY
	extension.pre_pipeline_mutate_camera_state(camera, state, 0.1)
	assert_almost_eq(extension.aim_target.z, -4.75, 0.1)

func test_listener_applies_nonzero_impulse_correction() -> void:
	var manager: CameramanImpulseManager = CameramanCore.get_impulse_manager()
	manager.clear()
	CameramanCore.current_time_override = 0.0
	var event: CameramanImpulseEvent = CameramanImpulseEvent.new()
	event.position = Vector3.ZERO
	event.signal_velocity = Vector3.ONE
	event.duration = 1.0
	event.channel = 1
	event.start_time = 0.0
	manager.add_impulse_event(event)
	var listener: CameramanImpulseListener = CameramanImpulseListener.new()
	autofree(listener)
	var state: CameramanCameraState = CameramanCameraState.create_default()
	listener.mutate_camera_state(state, 0.1)
	assert_gt(state.position_correction.length(), 0.0)
	manager.clear()
	CameramanCore.current_time_override = -1.0

func test_storyboard_overlay_handlers_create_and_hide() -> void:
	var camera: Node3D = Node3D.new()
	add_child_autofree(camera)
	var storyboard: CameramanStoryboard = CameramanStoryboard.new()
	camera.add_child(storyboard)
	storyboard.on_camera_activated(camera, null)
	assert_gt(storyboard.get_child_count(), 0)
	storyboard.on_camera_deactivated(camera, null)

func test_propagating_impulse_arrives_late() -> void:
	var definition: CameramanImpulseDefinition = CameramanImpulseDefinition.new()
	definition.impulse_type = CameramanImpulseDefinition.ImpulseType.PROPAGATING
	definition.propagation_speed = 10.0
	definition.impulse_duration = 1.0
	CameramanCore.current_time_override = 0.0
	var event: CameramanImpulseEvent = definition.create_event(Vector3.ONE, Vector3.ZERO)
	var manager: CameramanImpulseManager = CameramanImpulseManager.new()
	manager.add_impulse_event(event)
	CameramanCore.current_time_override = 0.5
	assert_almost_eq(
		(manager.get_impulse_at(Vector3(10.0, 0.0, 0.0), false, 1)[0] as Vector3).length(),
		0.0,
		0.001
	)
	CameramanCore.current_time_override = 1.1
	assert_gt((manager.get_impulse_at(Vector3(10.0, 0.0, 0.0), false, 1)[0] as Vector3).length(), 0.0)
	CameramanCore.current_time_override = -1.0

func test_recomposer_attachment_zero_keeps_previous_position() -> void:
	var extension: CameramanRecomposer = CameramanRecomposer.new()
	autofree(extension)
	var camera: Node = Node.new()
	autofree(camera)
	extension.follow_attachment = 0.0
	var state: CameramanCameraState = CameramanCameraState.create_default()
	state.raw_position = Vector3(3.0, 0.0, 0.0)
	extension.pre_pipeline_mutate_camera_state(camera, state, 0.1)
	state.raw_position = Vector3(9.0, 0.0, 0.0)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.FINALIZE, state, 0.1)
	assert_almost_eq(state.raw_position, Vector3(3.0, 0.0, 0.0), Vector3.ONE * 0.001)
