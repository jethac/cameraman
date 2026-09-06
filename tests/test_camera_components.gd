extends GutTest

class CountingExtension extends CameramanExtension:
	var calls: Dictionary = {}

	func post_pipeline_stage_callback(
		_camera: Node,
		stage: CameramanCore.Stage,
		_state: CameramanCameraState,
		_delta: float
	) -> void:
		calls[stage] = int(calls.get(stage, 0)) + 1

func test_hard_lock_and_hard_look_at() -> void:
	var target: Node3D = Node3D.new()
	target.position = Vector3(2.0, 3.0, 4.0)
	var lock_camera: CameramanCamera = CameramanCamera.new()
	lock_camera.set_follow(target)
	var lock: CameramanHardLockToTarget = CameramanHardLockToTarget.new()
	lock_camera.add_child(lock)
	var look_camera: CameramanCamera = CameramanCamera.new()
	look_camera.position = Vector3(2.0, 3.0, 0.0)
	look_camera.set_look_at(target)
	look_camera.use_separate_look_at = true
	look_camera.look_at_target = target
	var look: CameramanHardLookAt = CameramanHardLookAt.new()
	look_camera.add_child(look)
	var root: Node = Node.new()
	add_child_autofree(root)
	root.add_child(target)
	root.add_child(lock_camera)
	root.add_child(look_camera)
	lock_camera.update_state(Vector3.UP, 0.1)
	look_camera.update_state(Vector3.UP, 0.1)
	assert_almost_eq(lock_camera.get_state().raw_position, target.global_position, Vector3.ONE * 0.001)
	var direction: Vector3 = look_camera.get_state().raw_orientation * Vector3.FORWARD
	assert_true(direction.dot((target.global_position - look_camera.global_position).normalized()) > 0.99)

func test_follow_converges_to_offset() -> void:
	var target: Node3D = Node3D.new()
	target.position = Vector3(4.0, 0.0, 0.0)
	var camera: CameramanCamera = CameramanCamera.new()
	camera.set_follow(target)
	var follow: CameramanFollow = CameramanFollow.new()
	follow.follow_offset = Vector3(0.0, 0.0, 2.0)
	follow.binding_mode = CameramanFollow.BindingMode.WORLD_SPACE
	camera.add_child(follow)
	var root: Node = Node.new()
	add_child_autofree(root)
	root.add_child(target)
	root.add_child(camera)
	camera.update_state(Vector3.UP, 0.1)
	assert_almost_eq(
		camera.get_state().raw_position,
		target.global_position + follow.follow_offset,
		Vector3.ONE * 0.001
	)

func test_camera_without_components_preserves_transform() -> void:
	var camera: CameramanCamera = CameramanCamera.new()
	camera.position = Vector3(2.0, 4.0, 6.0)
	var root: Node = Node.new()
	add_child_autofree(root)
	root.add_child(camera)
	camera.update_state(Vector3.UP, 0.1)
	assert_almost_eq(camera.get_state().raw_position, Vector3(2.0, 4.0, 6.0), Vector3.ONE * 0.001)

func test_post_pipeline_callbacks_fire_once_per_stage() -> void:
	var root: Node = Node.new()
	var camera: CameramanCamera = CameramanCamera.new()
	var follow: CameramanFollow = CameramanFollow.new()
	var composer: CameramanPositionComposer = CameramanPositionComposer.new()
	var extension: CountingExtension = CountingExtension.new()
	camera.add_child(follow)
	camera.add_child(composer)
	camera.add_child(extension)
	root.add_child(camera)
	add_child_autofree(root)
	camera.update_state(Vector3.UP, 0.1)
	for stage in [
		CameramanCore.Stage.BODY,
		CameramanCore.Stage.AIM,
		CameramanCore.Stage.NOISE,
		CameramanCore.Stage.FINALIZE
	]:
		assert_eq(extension.calls.get(stage, 0), 1)

	var empty_camera: CameramanCamera = CameramanCamera.new()
	var empty_extension: CountingExtension = CountingExtension.new()
	empty_camera.add_child(empty_extension)
	root.add_child(empty_camera)
	empty_camera.update_state(Vector3.UP, 0.1)
	for stage in [
		CameramanCore.Stage.BODY,
		CameramanCore.Stage.AIM,
		CameramanCore.Stage.NOISE,
		CameramanCore.Stage.FINALIZE
	]:
		assert_eq(empty_extension.calls.get(stage, 0), 1)

func test_noise_only_adds_corrections() -> void:
	var profile: CameramanNoiseProfile = CameramanNoiseProfile.new()
	var channel: CameramanNoiseChannel = CameramanNoiseChannel.new()
	channel.x.amplitude = 1.0
	channel.x.constant = true
	profile.position_noise.append(channel)
	var component: CameramanBasicMultiChannelPerlin = CameramanBasicMultiChannelPerlin.new()
	component.noise_profile = profile
	add_child_autofree(component)
	var state: CameramanCameraState = CameramanCameraState.create_default()
	state.raw_position = Vector3(3.0, 2.0, 1.0)
	CameramanCore.current_time_override = 0.3
	component.mutate_camera_state(state, 0.1)
	CameramanCore.current_time_override = -1.0
	assert_almost_eq(state.raw_position, Vector3(3.0, 2.0, 1.0), Vector3.ONE * 0.001)
	assert_gt(state.position_correction.length(), 0.0)

func test_follow_binding_modes_converge() -> void:
	for mode in [
		CameramanFollow.BindingMode.LOCK_TO_TARGET_ON_ASSIGN,
		CameramanFollow.BindingMode.LOCK_TO_TARGET_WITH_WORLD_UP,
		CameramanFollow.BindingMode.LOCK_TO_TARGET_NO_ROLL,
		CameramanFollow.BindingMode.LOCK_TO_TARGET,
		CameramanFollow.BindingMode.WORLD_SPACE,
		CameramanFollow.BindingMode.LAZY_FOLLOW
	]:
		var root: Node = Node.new()
		var target: Node3D = Node3D.new()
		target.position = Vector3(4.0, 0.0, 0.0)
		target.rotation = Vector3(0.0, 0.4, 0.0)
		var camera: CameramanCamera = CameramanCamera.new()
		var follow: CameramanFollow = CameramanFollow.new()
		follow.follow_offset = Vector3(0.0, 0.0, 2.0)
		follow.binding_mode = mode
		camera.set_follow(target)
		camera.add_child(follow)
		root.add_child(target)
		root.add_child(camera)
		add_child_autofree(root)
		camera.update_state(Vector3.UP, 0.1)
		if mode == CameramanFollow.BindingMode.LAZY_FOLLOW:
			assert_almost_eq(
				camera.get_state().raw_position.distance_to(target.global_position),
				follow.follow_offset.length(),
				0.001
			)
			assert_lt(
				(camera.get_state().raw_position - target.global_position).dot(
					target.global_basis * Vector3.FORWARD
				),
				0.0
			)
		else:
			var expected: Vector3 = target.global_position
			if mode == CameramanFollow.BindingMode.WORLD_SPACE:
				expected += follow.follow_offset
			elif mode == CameramanFollow.BindingMode.LOCK_TO_TARGET_WITH_WORLD_UP:
				var forward: Vector3 = (target.global_basis * Vector3.FORWARD).slide(Vector3.UP).normalized()
				expected += Basis.looking_at(forward, Vector3.UP, false) * follow.follow_offset
			else:
				expected += target.global_basis * follow.follow_offset
			assert_almost_eq(camera.get_state().raw_position, expected, Vector3.ONE * 0.001)

func test_follow_on_assign_captures_identity_target_basis() -> void:
	var root: Node = Node.new()
	var target: Node3D = Node3D.new()
	var camera: CameramanCamera = CameramanCamera.new()
	var follow: CameramanFollow = CameramanFollow.new()
	follow.binding_mode = CameramanFollow.BindingMode.LOCK_TO_TARGET_ON_ASSIGN
	follow.follow_offset = Vector3(1.0, 0.0, 0.0)
	camera.set_follow(target)
	camera.add_child(follow)
	root.add_child(target)
	root.add_child(camera)
	add_child_autofree(root)
	camera.update_state(Vector3.UP, 0.1)
	target.rotation.y = PI * 0.5
	camera.update_state(Vector3.UP, 0.1)
	assert_almost_eq(
		camera.get_state().raw_position,
		target.global_position + Vector3(1.0, 0.0, 0.0),
		Vector3.ONE * 0.001
	)

func test_rotation_composer_reaches_screen_composition() -> void:
	var root: Node = Node.new()
	var target: Node3D = Node3D.new()
	target.position = Vector3(0.0, 0.0, -10.0)
	var camera: CameramanCamera = CameramanCamera.new()
	camera.set_look_at(target)
	camera.use_separate_look_at = true
	camera.look_at_target = target
	var composer: CameramanRotationComposer = CameramanRotationComposer.new()
	composer.composition.screen_position = Vector2(0.65, 0.5)
	composer.composition.dead_zone_enabled = true
	composer.composition.dead_zone_size = Vector2(0.03, 0.03)
	composer.damping = Vector2(0.5, 0.5)
	camera.add_child(composer)
	root.add_child(target)
	root.add_child(camera)
	add_child_autofree(root)
	for _index in 8:
		camera.update_state(Vector3.UP, 0.1)
	var screen_offset: Vector2 = CameramanComposerMath.project_screen_offset(
		camera.get_state().raw_position,
		camera.get_state().raw_orientation,
		target.global_position,
		camera.get_state().lens
	)
	assert_almost_eq(screen_offset.x, 0.15, 0.03)

func test_rotation_composer_recovers_target_outside_camera_frustum() -> void:
	var camera_position := Vector3(0.0, 8.0, 0.0)
	var orientation := Basis.looking_at(Vector3.FORWARD, Vector3.UP, false).get_rotation_quaternion()
	var target := Vector3(5.0, 0.0, 5.0)
	var lens := CameramanLens.new()
	var settings := CameramanScreenComposerSettings.new()
	var result := orientation
	for _index in 10:
		result = CameramanComposerMath.rotate_to_composition(
			camera_position,
			result,
			target,
			lens,
			settings,
			1.0 / 60.0,
			Vector2.ONE
		)
	var forward: Vector3 = result * Vector3.FORWARD
	var target_direction: Vector3 = (target - camera_position).normalized()
	assert_lt(forward.y, 0.0)
	assert_gt(forward.dot(target_direction), 0.95)

func test_rotation_composer_handles_target_parallel_to_up() -> void:
	var lens := CameramanLens.new()
	var result: Quaternion = CameramanComposerMath.rotate_to_composition(
		Vector3.ZERO,
		Quaternion.IDENTITY,
		Vector3(0.0, -5.0, 0.0),
		lens,
		CameramanScreenComposerSettings.new(),
		1.0 / 60.0,
		Vector2.ONE
	)
	var forward: Vector3 = result * Vector3.FORWARD
	assert_true(forward.is_finite())
	assert_gt(forward.dot(Vector3.DOWN), 0.99)

func test_rotation_composer_keeps_orientation_when_target_coincident() -> void:
	var lens := CameramanLens.new()
	var current: Quaternion = Quaternion(Vector3.UP, 0.7)
	var result: Quaternion = CameramanComposerMath.rotate_to_composition(
		Vector3(1.0, 2.0, 3.0),
		current,
		Vector3(1.0, 2.0, 3.0),
		lens,
		CameramanScreenComposerSettings.new(),
		1.0 / 60.0,
		Vector2.ONE
	)
	assert_true(result.is_finite())
	assert_almost_eq(result.angle_to(current), 0.0, 0.0001)

func test_rotation_composer_aims_from_corrected_position() -> void:
	var state := CameramanCameraState.create_default()
	state.raw_position = Vector3(0.0, 5.0, 0.0)
	state.position_correction = Vector3(10.0, 0.0, 0.0)
	state.raw_orientation = Quaternion.IDENTITY
	state.reference_look_at = Vector3(10.0, 0.0, -5.0)
	var composer := CameramanRotationComposer.new()
	autofree(composer)
	composer.mutate_camera_state(state, 0.1)
	var expected := Vector3(0.0, -0.7071068, -0.7071068)
	assert_gt((state.raw_orientation * Vector3.FORWARD).dot(expected), 0.99)

func test_hard_look_at_aims_from_corrected_position() -> void:
	var state := CameramanCameraState.create_default()
	state.raw_position = Vector3(0.0, 5.0, 0.0)
	state.position_correction = Vector3(10.0, 0.0, 0.0)
	state.reference_look_at = Vector3(10.0, 0.0, -5.0)
	var look_at := CameramanHardLookAt.new()
	autofree(look_at)
	look_at.mutate_camera_state(state, 0.1)
	var expected := Vector3(0.0, -0.7071068, -0.7071068)
	assert_gt((state.raw_orientation * Vector3.FORWARD).dot(expected), 0.99)

func test_position_composer_projects_from_corrected_position() -> void:
	var root := Node3D.new()
	var target := Node3D.new()
	target.position = Vector3(10.0, 0.0, -5.0)
	var camera := CameramanCamera.new()
	camera.look_at_target = target
	var composer := CameramanPositionComposer.new()
	camera.add_child(composer)
	root.add_child(target)
	root.add_child(camera)
	add_child_autofree(root)
	var state := CameramanCameraState.create_default()
	state.raw_position = Vector3(0.0, 5.0, 0.0)
	state.position_correction = Vector3(10.0, 0.0, 0.0)
	state.raw_orientation = Quaternion.IDENTITY
	composer.mutate_camera_state(state, 0.1)
	assert_almost_eq(state.raw_position, Vector3(0.0, 5.0, 0.0), Vector3.ONE * 0.001)
