extends GutTest

func test_orbital_sphere_preserves_radius() -> void:
	var orbital: CameramanOrbitalFollow = CameramanOrbitalFollow.new()
	orbital.radius = 6.0
	orbital.radial_axis.value = 6.0
	orbital.horizontal_axis.value = 37.0
	orbital.vertical_axis.value = 22.0
	add_child_autofree(orbital)
	assert_almost_eq(orbital.get_camera_point().length(), 6.0, 0.001)

func test_orbital_three_ring_extremes_match_rings() -> void:
	var orbital: CameramanOrbitalFollow = CameramanOrbitalFollow.new()
	orbital.orbit_style = CameramanOrbitalFollow.OrbitStyle.THREE_RING
	orbital.top_height = 4.0
	orbital.top_radius = 7.0
	orbital.bottom_height = -3.0
	orbital.bottom_radius = 2.0
	add_child_autofree(orbital)
	orbital.vertical_axis.value = orbital.vertical_axis.range.x
	var bottom: Vector3 = orbital.get_camera_point()
	orbital.vertical_axis.value = orbital.vertical_axis.range.y
	var top: Vector3 = orbital.get_camera_point()
	assert_almost_eq(bottom.y, -3.0, 0.001)
	assert_almost_eq(Vector2(bottom.x, bottom.z).length(), 2.0, 0.001)
	assert_almost_eq(top.y, 4.0, 0.001)
	assert_almost_eq(Vector2(top.x, top.z).length(), 7.0, 0.001)

func test_third_person_rig_follows_target_rotation() -> void:
	var root: Node = Node.new()
	var target: Node3D = Node3D.new()
	target.rotation.y = PI * 0.5
	var camera: CameramanCamera = CameramanCamera.new()
	camera.set_follow(target)
	var component: CameramanThirdPersonFollow = CameramanThirdPersonFollow.new()
	component.shoulder_offset = Vector3(1.0, 2.0, 0.0)
	component.vertical_arm_length = 1.0
	camera.add_child(component)
	root.add_child(target)
	root.add_child(camera)
	add_child_autofree(root)
	var rig: Array[Vector3] = component.get_rig_positions()
	assert_almost_eq(rig[0], target.global_position, Vector3.ONE * 0.001)
	assert_almost_eq(rig[1], target.global_position + target.global_basis * component.shoulder_offset, Vector3.ONE * 0.001)
	assert_almost_eq(rig[2], rig[1] + target.global_basis * Vector3.UP, Vector3.ONE * 0.001)

func test_position_composer_moves_target_into_dead_zone() -> void:
	var root: Node = Node.new()
	var target: Node3D = Node3D.new()
	target.position = Vector3(4.0, 0.0, -10.0)
	var camera: CameramanCamera = CameramanCamera.new()
	camera.set_look_at(target)
	camera.use_separate_look_at = true
	camera.look_at_target = target
	var composer: CameramanPositionComposer = CameramanPositionComposer.new()
	composer.composition.dead_zone_enabled = true
	composer.composition.dead_zone_size = Vector2(0.05, 0.05)
	composer.damping = Vector3(0.1, 0.1, 0.1)
	camera.add_child(composer)
	root.add_child(target)
	root.add_child(camera)
	add_child_autofree(root)
	for _index in 12:
		camera.update_state(Vector3.UP, 0.1)
	var offset: Vector2 = CameramanComposerMath.project_screen_offset(
		camera.get_state().raw_position,
		camera.get_state().raw_orientation,
		target.global_position,
		camera.get_state().lens
	)
	assert_lte(absf(offset.x), 0.08)

func test_spline_dolly_normalized_position() -> void:
	var path: Path3D = Path3D.new()
	var curve: Curve3D = Curve3D.new()
	curve.add_point(Vector3.ZERO)
	curve.add_point(Vector3(0.0, 0.0, -10.0))
	path.curve = curve
	var camera: CameramanCamera = CameramanCamera.new()
	var dolly: CameramanSplineDolly = CameramanSplineDolly.new()
	dolly.spline = path
	dolly.position_units = CameramanSplineDolly.PositionUnits.NORMALIZED
	dolly.camera_position = 0.5
	camera.add_child(dolly)
	var root: Node = Node.new()
	root.add_child(path)
	root.add_child(camera)
	add_child_autofree(root)
	camera.update_state(Vector3.UP, 0.1)
	assert_almost_eq(
		camera.get_state().raw_position,
		curve.sample_baked(curve.get_baked_length() * 0.5),
		Vector3.ONE * 0.001
	)

func test_spline_dolly_nearest_point_to_target() -> void:
	var path: Path3D = Path3D.new()
	var curve: Curve3D = Curve3D.new()
	curve.add_point(Vector3.ZERO)
	curve.add_point(Vector3(0.0, 0.0, -10.0))
	path.curve = curve
	var target: Node3D = Node3D.new()
	target.position = Vector3(0.0, 0.0, -7.0)
	var camera: CameramanCamera = CameramanCamera.new()
	camera.set_follow(target)
	var dolly: CameramanSplineDolly = CameramanSplineDolly.new()
	dolly.spline = path
	dolly.automatic_dolly.enabled = true
	dolly.automatic_dolly.mode = CameramanSplineAutoDolly.Mode.NEAREST_POINT_TO_TARGET
	camera.add_child(dolly)
	var root: Node = Node.new()
	root.add_child(path)
	root.add_child(target)
	root.add_child(camera)
	add_child_autofree(root)
	camera.update_state(Vector3.UP, 0.1)
	assert_almost_eq(camera.get_state().raw_position.z, -7.0, 0.05)

func test_pan_tilt_wraps_and_clamps() -> void:
	var component: CameramanPanTilt = CameramanPanTilt.new()
	add_child_autofree(component)
	component.pan_axis.set_value(190.0)
	component.tilt_axis.set_value(100.0)
	assert_almost_eq(component.pan_axis.value, -170.0, 0.001)
	assert_almost_eq(component.tilt_axis.value, 70.0, 0.001)

func test_rotate_with_follow_target_converges() -> void:
	var target: Node3D = Node3D.new()
	target.rotation.y = PI * 0.5
	var camera: CameramanCamera = CameramanCamera.new()
	camera.set_follow(target)
	var component: CameramanRotateWithFollowTarget = CameramanRotateWithFollowTarget.new()
	component.damping = 0.2
	camera.add_child(component)
	var root: Node = Node.new()
	root.add_child(target)
	root.add_child(camera)
	add_child_autofree(root)
	for _index in 12:
		camera.update_state(Vector3.UP, 0.1)
	assert_gt((camera.get_state().raw_orientation * Vector3.FORWARD).dot(
		target.global_basis * Vector3.FORWARD
	), 0.99)

func test_noise_zero_amplitude_has_zero_correction() -> void:
	var profile: CameramanNoiseProfile = CameramanNoiseProfile.new()
	var channel: CameramanNoiseChannel = CameramanNoiseChannel.new()
	profile.position_noise.append(channel)
	var component: CameramanBasicMultiChannelPerlin = CameramanBasicMultiChannelPerlin.new()
	component.noise_profile = profile
	add_child_autofree(component)
	var state: CameramanCameraState = CameramanCameraState.create_default()
	component.mutate_camera_state(state, 0.1)
	assert_almost_eq(state.position_correction, Vector3.ZERO, Vector3.ONE * 0.001)

func test_input_axis_recenters_after_wait() -> void:
	var axis: CameramanInputAxis = CameramanInputAxis.new()
	axis.recentering_enabled = true
	axis.recentering_wait = 0.2
	axis.recentering_time = 0.1
	axis.value = 1.0
	axis.do_recentering(0.1)
	assert_almost_eq(axis.value, 1.0, 0.001)
	axis.do_recentering(0.2)
	assert_lt(axis.value, 1.0)

func test_input_axis_driver_accelerates_toward_target() -> void:
	var driver: CameramanInputAxisDriver = CameramanInputAxisDriver.new()
	var first: float = driver.update(1.0, 0.1, 1.0, 1.0)
	var second: float = driver.update(1.0, 0.1, 1.0, 1.0)
	assert_gt(first, 0.0)
	assert_gt(second, first)

func test_input_controller_applies_mouse_motion_to_discovered_axis() -> void:
	var root: Node = Node.new()
	var camera: CameramanCamera = CameramanCamera.new()
	var orbital: CameramanOrbitalFollow = CameramanOrbitalFollow.new()
	var controller: CameramanInputAxisController = CameramanInputAxisController.new()
	camera.add_child(orbital)
	camera.add_child(controller)
	root.add_child(camera)
	add_child_autofree(root)
	controller.synchronize_controllers()
	var control: CameramanInputAxisControl = controller.get_controller("horizontal")
	control.mouse_motion_axis = CameramanInputAxisControl.MouseMotionAxis.X
	control.gain = 1.0
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.relative = Vector2(4.0, 0.0)
	controller._input(motion)
	controller._process(1.0 / 60.0)
	assert_almost_eq(orbital.horizontal_axis.value, 4.0, 0.001)

func test_spline_fixed_speed_advances_and_wraps_normalized_position() -> void:
	var root: Node3D = Node3D.new()
	var path: Path3D = Path3D.new()
	var curve: Curve3D = Curve3D.new()
	curve.add_point(Vector3.ZERO)
	curve.add_point(Vector3(0.0, 0.0, -10.0))
	path.curve = curve
	var camera: CameramanCamera = CameramanCamera.new()
	var spline: CameramanSplineDolly = CameramanSplineDolly.new()
	spline.spline = path
	spline.position_units = CameramanSplineDolly.PositionUnits.NORMALIZED
	spline.automatic_dolly.enabled = true
	spline.automatic_dolly.mode = CameramanSplineAutoDolly.Mode.FIXED_SPEED
	spline.automatic_dolly.speed = 2.0
	camera.add_child(spline)
	root.add_child(path)
	root.add_child(camera)
	add_child_autofree(root)
	camera.update_state(Vector3.UP, 0.1)
	camera.update_state(Vector3.UP, 0.6)
	assert_almost_eq(spline.camera_position, 0.4, 0.001)
