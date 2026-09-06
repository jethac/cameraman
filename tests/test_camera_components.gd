extends GutTest

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
