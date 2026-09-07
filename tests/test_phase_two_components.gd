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

func test_follow_rebases_camera_when_target_warps() -> void:
	var root: Node3D = Node3D.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	var target: Node3D = Node3D.new()
	var camera: CameramanCamera = CameramanCamera.new()
	camera.set_follow(target)
	var follow: CameramanFollow = CameramanFollow.new()
	follow.position_damping = Vector3.ONE
	camera.add_child(follow)
	output.add_child(brain)
	root.add_child(target)
	root.add_child(output)
	root.add_child(camera)
	add_child_autofree(root)
	for _index in 6:
		brain.manual_update(0.1)
	var settled_x: float = camera.get_state().get_final_position().x
	var warp: Vector3 = Vector3(100.0, 0.0, 0.0)
	target.position += warp
	CameramanCore.notify_target_warped(target, warp)
	brain.manual_update(0.1)
	assert_almost_eq(
		camera.get_state().get_final_position().x,
		settled_x + warp.x,
		0.5
	)

func test_orbital_rebases_camera_when_target_warps() -> void:
	var root: Node3D = Node3D.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	var target: Node3D = Node3D.new()
	var camera: CameramanCamera = CameramanCamera.new()
	camera.set_follow(target)
	var orbital: CameramanOrbitalFollow = CameramanOrbitalFollow.new()
	orbital.position_damping = Vector3.ONE
	orbital.radial_axis.value = 5.0
	camera.add_child(orbital)
	output.add_child(brain)
	root.add_child(target)
	root.add_child(output)
	root.add_child(camera)
	add_child_autofree(root)
	for _index in 6:
		brain.manual_update(0.1)
	var settled: Vector3 = camera.get_state().get_final_position()
	var warp: Vector3 = Vector3(100.0, 0.0, 0.0)
	target.position += warp
	CameramanCore.notify_target_warped(target, warp)
	brain.manual_update(0.1)
	assert_almost_eq(
		camera.get_state().get_final_position(),
		settled + warp,
		Vector3.ONE * 0.5
	)

func test_third_person_rebases_camera_when_target_warps() -> void:
	var root: Node3D = Node3D.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	var target: Node3D = Node3D.new()
	var camera: CameramanCamera = CameramanCamera.new()
	camera.set_follow(target)
	var follow: CameramanThirdPersonFollow = CameramanThirdPersonFollow.new()
	follow.shoulder_offset = Vector3(0.6, 1.6, 0.0)
	follow.camera_distance = 4.5
	follow.avoid_obstacles.enabled = false
	camera.add_child(follow)
	output.add_child(brain)
	root.add_child(target)
	root.add_child(output)
	root.add_child(camera)
	add_child_autofree(root)
	for _index in 6:
		brain.manual_update(0.1)
	var settled: Vector3 = camera.get_state().get_final_position()
	var warp: Vector3 = Vector3(100.0, 0.0, 0.0)
	target.position += warp
	CameramanCore.notify_target_warped(target, warp)
	brain.manual_update(0.1)
	assert_almost_eq(
		camera.get_state().get_final_position(),
		settled + warp,
		Vector3.ONE * 0.5
	)

func test_spline_dolly_does_not_rebase_camera_node_on_target_warp() -> void:
	var root: Node3D = Node3D.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	var target: Node3D = Node3D.new()
	var path: Path3D = Path3D.new()
	var curve: Curve3D = Curve3D.new()
	curve.add_point(Vector3.ZERO)
	curve.add_point(Vector3(0.0, 0.0, -10.0))
	path.curve = curve
	var camera: CameramanCamera = CameramanCamera.new()
	camera.set_follow(target)
	var dolly: CameramanSplineDolly = CameramanSplineDolly.new()
	dolly.spline = path
	dolly.position_damping = Vector3.ONE
	camera.add_child(dolly)
	output.add_child(brain)
	root.add_child(target)
	root.add_child(path)
	root.add_child(output)
	root.add_child(camera)
	add_child_autofree(root)
	for _index in 6:
		brain.manual_update(0.1)
	var before: Vector3 = camera.global_position
	var warp: Vector3 = Vector3(100.0, 0.0, 0.0)
	target.position += warp
	CameramanCore.notify_target_warped(target, warp)
	assert_almost_eq(camera.global_position, before, Vector3.ONE * 0.001)

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

func test_third_person_clear_path_preserves_exact_hand_position() -> void:
	var root: Node3D = Node3D.new()
	var camera: CameramanCamera = CameramanCamera.new()
	var follow: CameramanThirdPersonFollow = CameramanThirdPersonFollow.new()
	follow.avoid_obstacles.enabled = true
	follow.avoid_obstacles.camera_radius = 0.0
	camera.add_child(follow)
	root.add_child(camera)
	add_child_autofree(root)
	var hand: Vector3 = Vector3(0.5, 1.5, 0.0)
	var path: Dictionary = follow._cast_camera_path(
		camera,
		Vector3.ZERO,
		hand,
		Quaternion.IDENTITY,
		2.0
	)
	assert_almost_eq(path["hand"], hand, Vector3.ONE * 0.001)

func test_third_person_follow_ignores_follow_target_collision() -> void:
	var root: Node3D = Node3D.new()
	var target: CharacterBody3D = CharacterBody3D.new()
	target.add_to_group("player")
	var target_shape: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 2.0
	target_shape.shape = capsule
	target.add_child(target_shape)
	var camera: CameramanCamera = CameramanCamera.new()
	camera.tracking_target = target
	var follow: CameramanThirdPersonFollow = CameramanThirdPersonFollow.new()
	follow.shoulder_offset = Vector3(0.6, 1.6, 0.0)
	follow.vertical_arm_length = 0.3
	follow.camera_distance = 4.5
	var avoidance: CameramanObstacleAvoidance = CameramanObstacleAvoidance.new()
	avoidance.enabled = true
	avoidance.camera_radius = 0.3
	avoidance.ignore_group = &"player"
	follow.avoid_obstacles = avoidance
	camera.add_child(follow)
	root.add_child(target)
	root.add_child(camera)
	add_child_autofree(root)
	await get_tree().physics_frame
	await get_tree().physics_frame
	camera.update_state(Vector3.UP, 0.1)
	var rig: Array[Vector3] = follow.get_rig_positions()
	assert_almost_eq(
		camera.get_state().raw_position.distance_to(rig[2]),
		4.5,
		0.01
	)

func test_third_person_follow_filters_ignored_bodies_along_ray_and_sphere_casts() -> void:
	var root: Node3D = Node3D.new()
	var camera: CameramanCamera = CameramanCamera.new()
	var follow: CameramanThirdPersonFollow = CameramanThirdPersonFollow.new()
	follow.avoid_obstacles.enabled = true
	follow.avoid_obstacles.ignore_group = &"ignored_obstacle"
	follow.avoid_obstacles.camera_radius = 0.3
	camera.add_child(follow)
	var ignored: StaticBody3D = _add_test_obstacle(root, 2.0, true)
	_add_test_obstacle(root, 4.0, false)
	root.add_child(camera)
	add_child_autofree(root)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var exclusions: Array[RID] = []
	var ray_fraction: float = follow._cast_ray_fraction(
		camera,
		Vector3.ZERO,
		Vector3(0.0, 0.0, 6.0),
		exclusions
	)
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 0.3
	var sphere_fraction: float = follow._cast_shape(
		camera,
		sphere,
		Vector3.ZERO,
		Vector3(0.0, 0.0, 6.0),
		exclusions
	)
	assert_gt(ray_fraction, 0.5)
	assert_lt(ray_fraction, 0.8)
	assert_gt(sphere_fraction, 0.45)
	assert_lt(sphere_fraction, 0.8)
	assert_ne(ignored, null)

func test_third_person_follow_ignores_only_ignored_bodies() -> void:
	var root: Node3D = Node3D.new()
	var camera: CameramanCamera = CameramanCamera.new()
	var follow: CameramanThirdPersonFollow = CameramanThirdPersonFollow.new()
	follow.avoid_obstacles.enabled = true
	follow.avoid_obstacles.ignore_group = &"ignored_obstacle"
	follow.avoid_obstacles.camera_radius = 0.3
	camera.add_child(follow)
	_add_test_obstacle(root, 2.0, true)
	root.add_child(camera)
	add_child_autofree(root)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var exclusions: Array[RID] = []
	var ray_fraction: float = follow._cast_ray_fraction(
		camera,
		Vector3.ZERO,
		Vector3(0.0, 0.0, 6.0),
		exclusions
	)
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 0.3
	var sphere_fraction: float = follow._cast_shape(
		camera,
		sphere,
		Vector3.ZERO,
		Vector3(0.0, 0.0, 6.0),
		exclusions
	)
	assert_almost_eq(ray_fraction, 1.0, 0.001)
	assert_almost_eq(sphere_fraction, 1.0, 0.001)

func test_third_person_pre_excludes_many_ignored_sphere_obstacles() -> void:
	var root: Node3D = Node3D.new()
	var camera: CameramanCamera = CameramanCamera.new()
	var follow: CameramanThirdPersonFollow = CameramanThirdPersonFollow.new()
	follow.avoid_obstacles.enabled = true
	follow.avoid_obstacles.ignore_group = &"ignored_obstacle"
	follow.avoid_obstacles.camera_radius = 0.3
	camera.add_child(follow)
	for index in 10:
		_add_test_obstacle(root, 0.5 + float(index) * 0.5, true)
	root.add_child(camera)
	add_child_autofree(root)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var exclusions: Array[RID] = follow._get_collision_exclusions()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 0.3
	var fraction: float = follow._cast_shape(
		camera,
		sphere,
		Vector3.ZERO,
		Vector3(0.0, 0.0, 8.0),
		exclusions
	)
	assert_almost_eq(fraction, 1.0, 0.001)

func test_third_person_pre_excludes_many_ignored_ray_obstacles() -> void:
	var root: Node3D = Node3D.new()
	var camera: CameramanCamera = CameramanCamera.new()
	var follow: CameramanThirdPersonFollow = CameramanThirdPersonFollow.new()
	follow.avoid_obstacles.enabled = true
	follow.avoid_obstacles.ignore_group = &"ignored_obstacle"
	follow.avoid_obstacles.camera_radius = 0.0
	camera.add_child(follow)
	for index in 20:
		_add_test_obstacle(root, 0.5 + float(index) * 0.5, true)
	root.add_child(camera)
	add_child_autofree(root)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var exclusions: Array[RID] = follow._get_collision_exclusions()
	var fraction: float = follow._cast_ray_fraction(
		camera,
		Vector3.ZERO,
		Vector3(0.0, 0.0, 12.0),
		exclusions
	)
	assert_almost_eq(fraction, 1.0, 0.001)

func _add_test_obstacle(root: Node3D, z: float, ignored: bool) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.position.z = z
	if ignored:
		body.add_to_group("ignored_obstacle")
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(4.0, 4.0, 0.5)
	shape_node.shape = box
	body.add_child(shape_node)
	root.add_child(body)
	return body

func test_third_person_follow_respects_minimum_obstacle_distance() -> void:
	var root: Node3D = Node3D.new()
	var target: CharacterBody3D = CharacterBody3D.new()
	var target_shape: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 2.0
	target_shape.shape = capsule
	target.add_child(target_shape)
	var wall: StaticBody3D = StaticBody3D.new()
	wall.position = Vector3(0.6, 1.9, 1.5)
	var wall_shape: CollisionShape3D = CollisionShape3D.new()
	var wall_box: BoxShape3D = BoxShape3D.new()
	wall_box.size = Vector3(2.0, 2.0, 0.5)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	var camera: CameramanCamera = CameramanCamera.new()
	camera.tracking_target = target
	var follow: CameramanThirdPersonFollow = CameramanThirdPersonFollow.new()
	follow.shoulder_offset = Vector3(0.6, 1.6, 0.0)
	follow.vertical_arm_length = 0.3
	follow.camera_distance = 4.5
	var avoidance: CameramanObstacleAvoidance = CameramanObstacleAvoidance.new()
	avoidance.enabled = true
	avoidance.camera_radius = 0.3
	avoidance.minimum_distance_from_target = 0.6
	follow.avoid_obstacles = avoidance
	camera.add_child(follow)
	root.add_child(target)
	root.add_child(wall)
	root.add_child(camera)
	add_child_autofree(root)
	await get_tree().physics_frame
	await get_tree().physics_frame
	camera.update_state(Vector3.UP, 0.1)
	var rig: Array[Vector3] = follow.get_rig_positions()
	assert_gte(camera.get_state().raw_position.distance_to(rig[2]), 0.6)

func test_third_person_minimum_distance_stays_before_wall() -> void:
	var root: Node3D = Node3D.new()
	var target: Node3D = Node3D.new()
	var wall: StaticBody3D = StaticBody3D.new()
	wall.position.z = 0.5
	var wall_shape: CollisionShape3D = CollisionShape3D.new()
	var wall_box: BoxShape3D = BoxShape3D.new()
	wall_box.size = Vector3(4.0, 4.0, 0.1)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	var camera: CameramanCamera = CameramanCamera.new()
	var follow: CameramanThirdPersonFollow = CameramanThirdPersonFollow.new()
	camera.set_follow(target)
	follow.camera_distance = 2.0
	follow.avoid_obstacles.enabled = true
	follow.avoid_obstacles.camera_radius = 0.2
	follow.avoid_obstacles.minimum_distance_from_target = 2.0
	camera.add_child(follow)
	root.add_child(target)
	root.add_child(wall)
	root.add_child(camera)
	add_child_autofree(root)
	await get_tree().physics_frame
	await get_tree().physics_frame
	camera.update_state(Vector3.UP, 0.1)
	var camera_position: Vector3 = camera.get_state().raw_position
	assert_lte(camera_position.z, 0.7)

func test_third_person_follow_slides_shoulder_around_obstacle() -> void:
	var root: Node3D = Node3D.new()
	var target: CharacterBody3D = CharacterBody3D.new()
	var target_shape: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 2.0
	target_shape.shape = capsule
	target.add_child(target_shape)
	var wall: StaticBody3D = StaticBody3D.new()
	wall.position = Vector3(1.1, 1.6, 0.0)
	var wall_shape: CollisionShape3D = CollisionShape3D.new()
	var wall_box: BoxShape3D = BoxShape3D.new()
	wall_box.size = Vector3(1.0, 3.0, 3.0)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	var camera: CameramanCamera = CameramanCamera.new()
	camera.tracking_target = target
	var follow: CameramanThirdPersonFollow = CameramanThirdPersonFollow.new()
	follow.shoulder_offset = Vector3(0.6, 1.6, 0.0)
	follow.vertical_arm_length = 0.3
	follow.camera_distance = 4.5
	var avoidance: CameramanObstacleAvoidance = CameramanObstacleAvoidance.new()
	avoidance.enabled = true
	avoidance.camera_radius = 0.3
	avoidance.minimum_distance_from_target = 0.6
	follow.avoid_obstacles = avoidance
	camera.add_child(follow)
	root.add_child(target)
	root.add_child(wall)
	root.add_child(camera)
	add_child_autofree(root)
	await get_tree().physics_frame
	await get_tree().physics_frame
	camera.update_state(Vector3.UP, 0.1)
	var rig: Array[Vector3] = follow.get_rig_positions()
	var camera_position: Vector3 = camera.get_state().raw_position
	assert_gt(camera_position.z, 3.5)
	assert_lt(absf(camera_position.x), 0.6)
	assert_almost_eq(camera_position.x, 0.3, 0.15)
	assert_gt(camera_position.distance_to(rig[2]), 0.6)

func test_orbital_on_assign_captures_identity_target_basis() -> void:
	var root: Node = Node.new()
	var target: Node3D = Node3D.new()
	var camera: CameramanCamera = CameramanCamera.new()
	var orbital: CameramanOrbitalFollow = CameramanOrbitalFollow.new()
	orbital.binding_mode = CameramanTargetTracker.BindingMode.LOCK_TO_TARGET_ON_ASSIGN
	orbital.horizontal_axis.value = 0.0
	orbital.vertical_axis.value = 0.0
	orbital.radial_axis.value = 5.0
	camera.set_follow(target)
	camera.add_child(orbital)
	root.add_child(target)
	root.add_child(camera)
	add_child_autofree(root)
	camera.update_state(Vector3.UP, 0.1)
	target.rotation.y = PI * 0.5
	camera.update_state(Vector3.UP, 0.1)
	assert_almost_eq(
		camera.get_state().raw_position,
		target.global_position + Vector3(0.0, 0.0, 5.0),
		Vector3.ONE * 0.001
	)

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
	control.mouse_gain = 1.0
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.relative = Vector2(4.0, 0.0)
	controller._input(motion)
	controller._process(1.0 / 60.0)
	assert_almost_eq(orbital.horizontal_axis.value, 4.0, 0.001)

func test_input_controller_preserves_bindings_when_axes_resynchronize() -> void:
	var root: Node = Node.new()
	var camera: CameramanCamera = CameramanCamera.new()
	var orbital: CameramanOrbitalFollow = CameramanOrbitalFollow.new()
	var controller: CameramanInputAxisController = CameramanInputAxisController.new()
	camera.add_child(orbital)
	camera.add_child(controller)
	root.add_child(camera)
	add_child_autofree(root)
	controller.synchronize_controllers()
	var horizontal: CameramanInputAxisControl = controller.get_controller("horizontal")
	horizontal.input_action_negative = &"look_left"
	horizontal.input_action_positive = &"look_right"
	horizontal.mouse_motion_axis = CameramanInputAxisControl.MouseMotionAxis.X
	var second_component: CameramanPanTilt = CameramanPanTilt.new()
	camera.add_child(second_component)
	await get_tree().process_frame
	await get_tree().process_frame
	var synchronized: CameramanInputAxisControl = controller.get_controller("horizontal")
	assert_eq(synchronized, horizontal)
	assert_eq(synchronized.input_action_negative, &"look_left")
	assert_eq(synchronized.input_action_positive, &"look_right")
	assert_eq(synchronized.mouse_motion_axis, CameramanInputAxisControl.MouseMotionAxis.X)

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
