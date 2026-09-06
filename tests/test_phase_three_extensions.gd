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

func test_confiner_3d_capsule_uses_spherical_caps() -> void:
	var camera: Node3D = Node3D.new()
	add_child_autofree(camera)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 1.0
	capsule.height = 4.0
	shape.shape = capsule
	camera.add_child(shape)
	var extension: CameramanConfiner3D = CameramanConfiner3D.new()
	autofree(extension)
	var inside: CameramanCameraState = CameramanCameraState.create_default()
	inside.raw_position = Vector3(0.0, 1.5, 0.0)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, inside, 0.1)
	assert_almost_eq(inside.get_final_position(), inside.raw_position, Vector3.ONE * 0.001)
	var cap_point := Vector3(0.8, 1.8, 0.0)
	var cap: CameramanCameraState = CameramanCameraState.create_default()
	cap.raw_position = cap_point
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, cap, 0.1)
	var cap_center := Vector3(0.0, 1.0, 0.0)
	var cap_direction: Vector3 = (cap.get_final_position() - cap_center).normalized()
	assert_almost_eq(
		cap.get_final_position().distance_to(cap_center),
		1.0,
		0.001
	)
	assert_almost_eq(
		cap_direction,
		(cap_point - cap_center).normalized(),
		Vector3.ONE * 0.001
	)
	var top: CameramanCameraState = CameramanCameraState.create_default()
	top.raw_position = Vector3(0.0, 3.0, 0.0)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, top, 0.1)
	assert_almost_eq(top.get_final_position(), Vector3(0.0, 2.0, 0.0), Vector3.ONE * 0.001)

func test_confiner_3d_clamps_convex_tetrahedron() -> void:
	var camera: Node3D = Node3D.new()
	add_child_autofree(camera)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var convex: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	convex.points = PackedVector3Array([
		Vector3.ZERO,
		Vector3(4.0, 0.0, 0.0),
		Vector3(0.0, 4.0, 0.0),
		Vector3(0.0, 0.0, 4.0)
	])
	shape.shape = convex
	camera.add_child(shape)
	var extension: CameramanConfiner3D = CameramanConfiner3D.new()
	autofree(extension)
	var inside: CameramanCameraState = CameramanCameraState.create_default()
	inside.raw_position = Vector3.ONE
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, inside, 0.1)
	assert_almost_eq(inside.get_final_position(), Vector3.ONE, Vector3.ONE * 0.001)
	var face: CameramanCameraState = CameramanCameraState.create_default()
	face.raw_position = Vector3(3.0, 3.0, 3.0)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, face, 0.1)
	assert_almost_eq(
		face.get_final_position(),
		Vector3.ONE * (4.0 / 3.0),
		Vector3.ONE * 0.01
	)
	var side: CameramanCameraState = CameramanCameraState.create_default()
	side.raw_position = Vector3(-2.0, 1.0, 1.0)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, side, 0.1)
	assert_almost_eq(side.get_final_position(), Vector3(0.0, 1.0, 1.0), Vector3.ONE * 0.01)

func test_confiner_3d_convex_hull_handles_coplanar_box_points() -> void:
	var camera: Node3D = Node3D.new()
	add_child_autofree(camera)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var convex: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	convex.points = PackedVector3Array([
		Vector3(-1.0, -1.0, -1.0),
		Vector3(1.0, -1.0, -1.0),
		Vector3(-1.0, 1.0, -1.0),
		Vector3(1.0, 1.0, -1.0),
		Vector3(-1.0, -1.0, 1.0),
		Vector3(1.0, -1.0, 1.0),
		Vector3(-1.0, 1.0, 1.0),
		Vector3(1.0, 1.0, 1.0)
	])
	shape.shape = convex
	camera.add_child(shape)
	var extension: CameramanConfiner3D = CameramanConfiner3D.new()
	autofree(extension)
	var inside: CameramanCameraState = CameramanCameraState.create_default()
	inside.raw_position = Vector3(0.5, 0.5, 0.5)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, inside, 0.1)
	assert_almost_eq(inside.get_final_position(), Vector3.ONE * 0.5, Vector3.ONE * 0.001)
	var outside: CameramanCameraState = CameramanCameraState.create_default()
	outside.raw_position = Vector3(5.0, 0.0, 0.0)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, outside, 0.1)
	assert_almost_eq(outside.get_final_position(), Vector3(1.0, 0.0, 0.0), Vector3.ONE * 0.01)
	var edge_aligned: CameramanCameraState = CameramanCameraState.create_default()
	edge_aligned.raw_position = Vector3.ZERO
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, edge_aligned, 0.1)
	assert_almost_eq(edge_aligned.get_final_position(), Vector3.ZERO, Vector3.ONE * 0.001)
	var tetra: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	tetra.set_faces(PackedVector3Array([
		Vector3.ZERO, Vector3(2.0, 0.0, 0.0), Vector3(0.0, 2.0, 0.0),
		Vector3.ZERO, Vector3(0.0, 2.0, 0.0), Vector3(0.0, 0.0, 2.0),
		Vector3.ZERO, Vector3(0.0, 0.0, 2.0), Vector3(2.0, 0.0, 0.0),
		Vector3(2.0, 0.0, 0.0), Vector3(0.0, 0.0, 2.0), Vector3(0.0, 2.0, 0.0)
	]))
	shape.shape = tetra
	var tetra_inside: CameramanCameraState = CameramanCameraState.create_default()
	tetra_inside.raw_position = Vector3(0.25, 0.25, 0.25)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, tetra_inside, 0.1)
	assert_almost_eq(
		tetra_inside.get_final_position(),
		tetra_inside.raw_position,
		Vector3.ONE * 0.001
	)

func test_confiner_3d_incremental_hull_handles_sphere_samples() -> void:
	var camera: Node3D = Node3D.new()
	add_child_autofree(camera)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var convex: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	var points: PackedVector3Array = PackedVector3Array()
	for index in range(400):
		var fraction: float = (float(index) + 0.5) / 400.0
		var y: float = 1.0 - 2.0 * fraction
		var radial: float = sqrt(1.0 - y * y)
		var angle: float = float(index) * PI * (3.0 - sqrt(5.0))
		points.append(
			Vector3(cos(angle) * radial, y, sin(angle) * radial) * 3.0
		)
	convex.points = points
	shape.shape = convex
	camera.add_child(shape)
	var extension: CameramanConfiner3D = CameramanConfiner3D.new()
	autofree(extension)
	var outside: CameramanCameraState = CameramanCameraState.create_default()
	outside.raw_position = Vector3(5.0, 0.0, 0.0)
	var start_msec: int = Time.get_ticks_msec()
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, outside, 0.1)
	var elapsed_msec: int = Time.get_ticks_msec() - start_msec
	assert_lt(elapsed_msec, 1000)
	assert_almost_eq(outside.get_final_position().length(), 3.0, 0.15)
	var inside: CameramanCameraState = CameramanCameraState.create_default()
	inside.raw_position = Vector3.ONE
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, inside, 0.1)
	assert_almost_eq(inside.get_final_position(), Vector3.ONE, Vector3.ONE * 0.001)

func test_confiner_3d_hull_handles_millimetre_scale() -> void:
	var camera: Node3D = Node3D.new()
	add_child_autofree(camera)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var convex: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	convex.points = PackedVector3Array([
		Vector3(-0.001, -0.001, -0.001), Vector3(0.001, -0.001, -0.001),
		Vector3(-0.001, 0.001, -0.001), Vector3(0.001, 0.001, -0.001),
		Vector3(-0.001, -0.001, 0.001), Vector3(0.001, -0.001, 0.001),
		Vector3(-0.001, 0.001, 0.001), Vector3(0.001, 0.001, 0.001)
	])
	shape.shape = convex
	camera.add_child(shape)
	var extension: CameramanConfiner3D = CameramanConfiner3D.new()
	autofree(extension)
	var outside: CameramanCameraState = CameramanCameraState.create_default()
	outside.raw_position = Vector3(0.002, 0.0, 0.0)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, outside, 0.1)
	assert_false(extension._cached_faces.is_empty())
	assert_almost_eq(
		outside.get_final_position(),
		Vector3(0.001, 0.0, 0.0),
		Vector3.ONE * 0.00001
	)
	var inside: CameramanCameraState = CameramanCameraState.create_default()
	inside.raw_position = Vector3(0.0005, 0.0, 0.0)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, inside, 0.1)
	assert_almost_eq(inside.get_final_position(), inside.raw_position, Vector3.ONE * 0.00001)

func test_confiner_3d_invalidates_cache_when_shape_points_change() -> void:
	var camera: Node3D = Node3D.new()
	add_child_autofree(camera)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var convex: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	convex.points = PackedVector3Array([
		Vector3(-2.0, -2.0, -2.0), Vector3(2.0, -2.0, -2.0),
		Vector3(-2.0, 2.0, -2.0), Vector3(2.0, 2.0, -2.0),
		Vector3(-2.0, -2.0, 2.0), Vector3(2.0, -2.0, 2.0),
		Vector3(-2.0, 2.0, 2.0), Vector3(2.0, 2.0, 2.0),
	])
	shape.shape = convex
	camera.add_child(shape)
	var extension: CameramanConfiner3D = CameramanConfiner3D.new()
	autofree(extension)
	var first: CameramanCameraState = CameramanCameraState.create_default()
	first.raw_position = Vector3(3.0, 0.0, 0.0)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, first, 0.1)
	assert_almost_eq(first.get_final_position().x, 2.0, 0.01)
	convex.points = PackedVector3Array([
		Vector3(-1.0, -1.0, -1.0), Vector3(1.0, -1.0, -1.0),
		Vector3(-1.0, 1.0, -1.0), Vector3(1.0, 1.0, -1.0),
		Vector3(-1.0, -1.0, 1.0), Vector3(1.0, -1.0, 1.0),
		Vector3(-1.0, 1.0, 1.0), Vector3(1.0, 1.0, 1.0),
	])
	var second: CameramanCameraState = CameramanCameraState.create_default()
	second.raw_position = Vector3(3.0, 0.0, 0.0)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, second, 0.1)
	assert_almost_eq(second.get_final_position().x, 1.0, 0.01)

func test_confiner_3d_clamps_concave_cube_faces() -> void:
	var camera: Node3D = Node3D.new()
	add_child_autofree(camera)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var concave: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	var corners: Array[Vector3] = [
		Vector3(-1.0, -1.0, -1.0),
		Vector3(1.0, -1.0, -1.0),
		Vector3(1.0, 1.0, -1.0),
		Vector3(-1.0, 1.0, -1.0),
		Vector3(-1.0, -1.0, 1.0),
		Vector3(1.0, -1.0, 1.0),
		Vector3(1.0, 1.0, 1.0),
		Vector3(-1.0, 1.0, 1.0)
	]
	concave.set_faces(PackedVector3Array([
		corners[0], corners[1], corners[2], corners[0], corners[2], corners[3],
		corners[4], corners[6], corners[5], corners[4], corners[7], corners[6],
		corners[0], corners[4], corners[5], corners[0], corners[5], corners[1],
		corners[3], corners[2], corners[6], corners[3], corners[6], corners[7],
		corners[0], corners[3], corners[7], corners[0], corners[7], corners[4],
		corners[1], corners[5], corners[6], corners[1], corners[6], corners[2]
	]))
	shape.shape = concave
	camera.add_child(shape)
	var extension: CameramanConfiner3D = CameramanConfiner3D.new()
	autofree(extension)
	var inside: CameramanCameraState = CameramanCameraState.create_default()
	inside.raw_position = Vector3(0.2, 0.2, 0.2)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, inside, 0.1)
	assert_almost_eq(inside.get_final_position(), Vector3.ONE * 0.2, Vector3.ONE * 0.001)
	var outside: CameramanCameraState = CameramanCameraState.create_default()
	outside.raw_position = Vector3(3.0, 0.0, 0.0)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, outside, 0.1)
	assert_almost_eq(outside.get_final_position(), Vector3(1.0, 0.0, 0.0), Vector3.ONE * 0.01)

func test_confiner_3d_slowing_distance_bypasses_damping() -> void:
	var camera: Node3D = Node3D.new()
	add_child_autofree(camera)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(4.0, 4.0, 4.0)
	shape.shape = box
	camera.add_child(shape)
	var extension: CameramanConfiner3D = CameramanConfiner3D.new()
	extension.damping = Vector3.ONE
	extension.slowing_distance = 10.0
	autofree(extension)
	var state: CameramanCameraState = CameramanCameraState.create_default()
	state.raw_position = Vector3(4.0, 0.0, 0.0)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, state, 0.1)
	assert_almost_eq(state.get_final_position(), Vector3(2.0, 0.0, 0.0), Vector3.ONE * 0.001)

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

func test_external_impulse_listener_returns_to_baseline() -> void:
	var manager: CameramanImpulseManager = CameramanCore.get_impulse_manager()
	manager.clear()
	CameramanCore.current_time_override = 0.0
	var event: CameramanImpulseEvent = CameramanImpulseEvent.new()
	event.position = Vector3.ZERO
	event.signal_velocity = Vector3.ONE
	event.duration = 1.0
	event.channel = 1
	event.start_time = 0.0
	var root: Node3D = Node3D.new()
	var listener: CameramanExternalImpulseListener = CameramanExternalImpulseListener.new()
	listener.position = Vector3(3.0, 0.0, 0.0)
	root.add_child(listener)
	add_child_autofree(root)
	var baseline: Vector3 = listener.global_position
	manager.add_impulse_event(event)
	listener._process(0.1)
	assert_gt(listener.global_position.distance_to(baseline), 0.0)
	CameramanCore.current_time_override = 2.0
	listener._process(1.9)
	assert_almost_eq(listener.global_position, baseline, Vector3.ONE * 0.001)
	manager.clear()
	CameramanCore.current_time_override = -1.0

func test_pixel_perfect_uses_full_orthographic_display() -> void:
	var camera: Node3D = Node3D.new()
	var extension: CameramanPixelPerfect = CameramanPixelPerfect.new()
	var state: CameramanCameraState = CameramanCameraState.create_default()
	state.lens.mode_override = CameramanLens.Mode.ORTHOGRAPHIC
	state.lens.orthographic_size = 5.0
	state.raw_position = Vector3(0.012, 0.012, 0.0)
	camera.add_child(extension)
	add_child_autofree(camera)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.FINALIZE, state, 0.1)
	var viewport_size: Vector2 = camera.get_viewport().get_visible_rect().size
	var pixel_size: Vector2 = Vector2(
		state.lens.orthographic_size * 2.0 * CameramanCameraState.aspect_ratio / viewport_size.x,
		state.lens.orthographic_size * 2.0 / viewport_size.y
	)
	assert_almost_eq(state.raw_position.x, snappedf(0.012, pixel_size.x), 0.0001)
	assert_almost_eq(state.raw_position.y, snappedf(0.012, pixel_size.y), 0.0001)

func test_storyboard_overlay_handlers_create_and_hide() -> void:
	var camera: Node3D = Node3D.new()
	add_child_autofree(camera)
	var storyboard: CameramanStoryboard = CameramanStoryboard.new()
	camera.add_child(storyboard)
	storyboard.on_camera_activated(camera, null)
	assert_gt(storyboard.get_child_count(), 0)
	storyboard.on_camera_deactivated(camera, null)

func test_storyboard_world_space_fills_output_frustum() -> void:
	var root: Node3D = Node3D.new()
	var output: Camera3D = Camera3D.new()
	output.fov = 90.0
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	output.add_child(brain)
	root.add_child(output)
	var camera: CameramanCamera = CameramanCamera.new()
	var storyboard: CameramanStoryboard = CameramanStoryboard.new()
	storyboard.render_mode = CameramanStoryboard.RenderMode.WORLD_SPACE
	storyboard.aspect = CameramanStoryboard.Aspect.STRETCH_TO_FIT
	storyboard.world_distance = 2.0
	storyboard.image = ImageTexture.create_from_image(
		Image.create(64, 64, false, Image.FORMAT_RGBA8)
	)
	camera.add_child(storyboard)
	root.add_child(camera)
	add_child_autofree(root)
	brain.manual_update(0.1)
	output.fov = 90.0
	storyboard._process(0.1)
	var quad: MeshInstance3D = storyboard.get_child(0) as MeshInstance3D
	assert_not_null(quad)
	assert_eq(storyboard.get_child_count(), 1)
	var viewport_size: Vector2 = output.get_viewport().get_visible_rect().size
	var viewport_aspect: float = viewport_size.x / viewport_size.y
	var quad_mesh: QuadMesh = quad.mesh as QuadMesh
	assert_almost_eq(quad_mesh.size.y, 4.0, 0.01)
	assert_almost_eq(quad_mesh.size.x, 4.0 * viewport_aspect, 0.01)
	assert_almost_eq(
		quad.global_position,
		output.global_position + output.global_basis * Vector3(0.0, 0.0, -2.0),
		Vector3.ONE * 0.01
	)

func test_storyboard_world_space_supports_shifted_frustum_projection() -> void:
	var root: Node3D = Node3D.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	output.add_child(brain)
	root.add_child(output)
	var camera: CameramanCamera = CameramanCamera.new()
	var storyboard: CameramanStoryboard = CameramanStoryboard.new()
	storyboard.render_mode = CameramanStoryboard.RenderMode.WORLD_SPACE
	storyboard.aspect = CameramanStoryboard.Aspect.STRETCH_TO_FIT
	storyboard.world_distance = 2.0
	storyboard.image = ImageTexture.create_from_image(
		Image.create(64, 64, false, Image.FORMAT_RGBA8)
	)
	camera.add_child(storyboard)
	root.add_child(camera)
	add_child_autofree(root)
	brain.manual_update(0.1)
	output.projection = Camera3D.PROJECTION_FRUSTUM
	output.size = 2.0
	output.near = 1.0
	output.frustum_offset = Vector2(0.5, 0.0)
	storyboard._process(0.1)
	var quad: MeshInstance3D = storyboard.get_child(0) as MeshInstance3D
	var quad_mesh: QuadMesh = quad.mesh as QuadMesh
	assert_almost_eq(quad_mesh.size.y, 4.0, 0.01)
	assert_almost_eq(
		quad.global_position,
		output.global_position + Vector3(1.0, 0.0, -2.0),
		Vector3.ONE * 0.01
	)

func test_storyboard_world_space_clamps_distance_to_clip_range() -> void:
	var root: Node3D = Node3D.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	output.add_child(brain)
	root.add_child(output)
	var camera: CameramanCamera = CameramanCamera.new()
	var storyboard: CameramanStoryboard = CameramanStoryboard.new()
	storyboard.render_mode = CameramanStoryboard.RenderMode.WORLD_SPACE
	storyboard.aspect = CameramanStoryboard.Aspect.STRETCH_TO_FIT
	storyboard.image = ImageTexture.create_from_image(
		Image.create(32, 32, false, Image.FORMAT_RGBA8)
	)
	camera.add_child(storyboard)
	root.add_child(camera)
	add_child_autofree(root)
	brain.manual_update(0.1)
	output.near = 0.5
	output.far = 10.0
	storyboard.world_distance = 0.1
	storyboard._process(0.1)
	var quad: MeshInstance3D = storyboard.get_child(0) as MeshInstance3D
	var near_distance: float = -output.global_basis.z.dot(
		quad.global_position - output.global_position
	)
	assert_almost_eq(near_distance, 0.506, 0.0001)
	storyboard.world_distance = 50.0
	storyboard._process(0.1)
	var far_distance: float = -output.global_basis.z.dot(
		quad.global_position - output.global_position
	)
	assert_lte(far_distance, 9.9)

func test_storyboard_world_layers_are_isolated() -> void:
	var root: Node3D = Node3D.new()
	var first_camera: CameramanCamera = CameramanCamera.new()
	var second_camera: CameramanCamera = CameramanCamera.new()
	var first: CameramanStoryboard = CameramanStoryboard.new()
	var second: CameramanStoryboard = CameramanStoryboard.new()
	first.world_render_layers = 2
	second.world_render_layers = 4
	first_camera.add_child(first)
	second_camera.add_child(second)
	root.add_child(first_camera)
	root.add_child(second_camera)
	add_child_autofree(root)
	first._create_world_space()
	second._create_world_space()
	assert_eq((first.get_child(0) as MeshInstance3D).layers, 2)
	assert_eq((second.get_child(0) as MeshInstance3D).layers, 4)
	assert_ne(
		(first.get_child(0) as MeshInstance3D).layers,
		(second.get_child(0) as MeshInstance3D).layers
	)

func test_storyboard_visibility_resolves_live_clear_shot_child() -> void:
	var root: Node3D = Node3D.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	var manager: CameramanClearShot = CameramanClearShot.new()
	var selected: CameramanCamera = CameramanCamera.new()
	selected.priority_enabled = true
	selected.priority = 2
	var unselected: CameramanCamera = CameramanCamera.new()
	unselected.priority_enabled = true
	unselected.priority = 1
	var selected_storyboard: CameramanStoryboard = CameramanStoryboard.new()
	selected_storyboard.image = ImageTexture.create_from_image(
		Image.create(8, 8, false, Image.FORMAT_RGBA8)
	)
	var unselected_storyboard: CameramanStoryboard = CameramanStoryboard.new()
	unselected_storyboard.image = selected_storyboard.image
	selected.add_child(selected_storyboard)
	unselected.add_child(unselected_storyboard)
	manager.add_child(selected)
	manager.add_child(unselected)
	output.add_child(brain)
	root.add_child(output)
	root.add_child(manager)
	add_child_autofree(root)
	brain.manual_update(0.1)
	selected_storyboard._process(0.1)
	unselected_storyboard._process(0.1)
	var selected_rect: TextureRect = (
		selected_storyboard.get_child(0).get_child(0).get_child(0) as TextureRect
	)
	var unselected_rect: TextureRect = (
		unselected_storyboard.get_child(0).get_child(0).get_child(0) as TextureRect
	)
	assert_true(selected_rect.visible)
	assert_false(unselected_rect.visible)

func test_storyboard_visibility_resolves_nested_live_managers() -> void:
	var root: Node3D = Node3D.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	var outer: CameramanCameraManagerBase = CameramanCameraManagerBase.new()
	var inner: CameramanCameraManagerBase = CameramanCameraManagerBase.new()
	var leaf: CameramanCamera = CameramanCamera.new()
	var storyboard: CameramanStoryboard = CameramanStoryboard.new()
	storyboard.image = ImageTexture.create_from_image(
		Image.create(8, 8, false, Image.FORMAT_RGBA8)
	)
	leaf.add_child(storyboard)
	inner.add_child(leaf)
	outer.add_child(inner)
	output.add_child(brain)
	root.add_child(output)
	root.add_child(outer)
	add_child_autofree(root)
	brain.manual_update(0.1)
	storyboard._process(0.1)
	var texture_rect: TextureRect = (
		storyboard.get_child(0).get_child(0).get_child(0) as TextureRect
	)
	assert_true(texture_rect.visible)

func test_find_brain_for_resolves_channel_specific_manager_leaves() -> void:
	var root: Node3D = Node3D.new()
	var output_one: Camera3D = Camera3D.new()
	var output_two: Camera3D = Camera3D.new()
	var brain_one: CameramanBrain = CameramanBrain.new()
	var brain_two: CameramanBrain = CameramanBrain.new()
	brain_one.update_method = CameramanBrain.UpdateMethod.MANUAL
	brain_two.update_method = CameramanBrain.UpdateMethod.MANUAL
	brain_one.channel_mask = 1
	brain_two.channel_mask = 2
	var manager_one: CameramanCameraManagerBase = CameramanCameraManagerBase.new()
	var manager_two: CameramanCameraManagerBase = CameramanCameraManagerBase.new()
	manager_one.output_channel = 1
	manager_two.output_channel = 2
	var leaf_one: CameramanCamera = CameramanCamera.new()
	var leaf_two: CameramanCamera = CameramanCamera.new()
	leaf_one.output_channel = 1
	leaf_two.output_channel = 2
	manager_one.add_child(leaf_one)
	manager_two.add_child(leaf_two)
	output_one.add_child(brain_one)
	output_two.add_child(brain_two)
	root.add_child(output_one)
	root.add_child(output_two)
	root.add_child(manager_one)
	root.add_child(manager_two)
	add_child_autofree(root)
	brain_one.manual_update(0.1)
	brain_two.manual_update(0.1)
	assert_eq(CameramanCore.find_brain_for(leaf_one), brain_one)
	assert_eq(CameramanCore.find_brain_for(leaf_two), brain_two)

func test_storyboard_world_space_updates_after_brain_same_frame() -> void:
	var root: Node3D = Node3D.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.PROCESS
	brain.default_blend.style = CameramanBlendDefinition.Style.CUT
	var camera: CameramanCamera = CameramanCamera.new()
	camera.priority_enabled = true
	camera.priority = 1
	camera.position = Vector3(1.0, 2.0, 3.0)
	var storyboard: CameramanStoryboard = CameramanStoryboard.new()
	storyboard.render_mode = CameramanStoryboard.RenderMode.WORLD_SPACE
	storyboard.world_distance = 2.0
	storyboard.image = ImageTexture.create_from_image(
		Image.create(16, 16, false, Image.FORMAT_RGBA8)
	)
	camera.add_child(storyboard)
	output.add_child(brain)
	root.add_child(output)
	root.add_child(camera)
	add_child_autofree(root)
	await get_tree().process_frame
	camera.position = Vector3(7.0, 2.0, 3.0)
	await get_tree().process_frame
	var quad: MeshInstance3D = storyboard.get_child(0) as MeshInstance3D
	var expected: Vector3 = (
		output.global_position
		+ output.global_basis * Vector3(0.0, 0.0, -storyboard.world_distance)
	)
	assert_almost_eq(quad.global_position, expected, Vector3.ONE * 0.001)

func test_storyboard_switches_render_modes() -> void:
	var root: Node3D = Node3D.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	output.add_child(brain)
	root.add_child(output)
	var camera: CameramanCamera = CameramanCamera.new()
	var storyboard: CameramanStoryboard = CameramanStoryboard.new()
	storyboard.render_mode = CameramanStoryboard.RenderMode.WORLD_SPACE
	storyboard.image = ImageTexture.create_from_image(
		Image.create(16, 16, false, Image.FORMAT_RGBA8)
	)
	camera.add_child(storyboard)
	root.add_child(camera)
	add_child_autofree(root)
	brain.manual_update(0.1)
	storyboard._process(0.1)
	assert_true(storyboard.get_child(0) is MeshInstance3D)
	storyboard.render_mode = CameramanStoryboard.RenderMode.SCREEN_SPACE_OVERLAY
	storyboard._process(0.1)
	assert_true(storyboard.get_child(0) is CanvasLayer)
	assert_eq((storyboard.get_child(0) as CanvasLayer).layer, 100)
	storyboard.render_mode = CameramanStoryboard.RenderMode.SCREEN_SPACE_CAMERA
	storyboard._process(0.1)
	assert_true(storyboard.get_child(0) is CanvasLayer)
	assert_eq((storyboard.get_child(0) as CanvasLayer).layer, 1)

func test_storyboard_camera_space_binds_output_viewport() -> void:
	var root: Node = Node.new()
	var subviewport: SubViewport = SubViewport.new()
	subviewport.size = Vector2i(320, 240)
	subviewport.world_3d = World3D.new()
	root.add_child(subviewport)
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	output.add_child(brain)
	subviewport.add_child(output)
	var camera: CameramanCamera = CameramanCamera.new()
	var storyboard: CameramanStoryboard = CameramanStoryboard.new()
	storyboard.render_mode = CameramanStoryboard.RenderMode.SCREEN_SPACE_CAMERA
	storyboard.image = ImageTexture.create_from_image(
		Image.create(16, 16, false, Image.FORMAT_RGBA8)
	)
	camera.add_child(storyboard)
	root.add_child(camera)
	add_child_autofree(root)
	brain.manual_update(0.1)
	storyboard._process(0.1)
	var layer: CanvasLayer = storyboard.get_child(0) as CanvasLayer
	var container: Control = layer.get_child(0) as Control
	assert_eq(layer.custom_viewport, subviewport)
	assert_almost_eq(container.size, Vector2(320.0, 240.0), Vector2.ONE * 0.001)
	storyboard.render_mode = CameramanStoryboard.RenderMode.SCREEN_SPACE_OVERLAY
	storyboard._process(0.1)
	assert_null((storyboard.get_child(0) as CanvasLayer).custom_viewport)
	root.remove_child(subviewport)
	subviewport.free()

func test_storyboard_camera_space_binds_2d_output_viewport() -> void:
	var root: Node = Node.new()
	var subviewport: SubViewport = SubViewport.new()
	subviewport.size = Vector2i(320, 240)
	root.add_child(subviewport)
	var output: Camera2D = Camera2D.new()
	var brain: CameramanBrain2D = CameramanBrain2D.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	output.add_child(brain)
	subviewport.add_child(output)
	var camera: CameramanCamera = CameramanCamera.new()
	var storyboard: CameramanStoryboard = CameramanStoryboard.new()
	storyboard.render_mode = CameramanStoryboard.RenderMode.SCREEN_SPACE_CAMERA
	storyboard.image = ImageTexture.create_from_image(
		Image.create(16, 16, false, Image.FORMAT_RGBA8)
	)
	camera.add_child(storyboard)
	root.add_child(camera)
	add_child_autofree(root)
	brain.manual_update(0.1)
	storyboard._process(0.1)
	var layer: CanvasLayer = storyboard.get_child(0) as CanvasLayer
	assert_eq(layer.custom_viewport, subviewport)
	root.remove_child(subviewport)
	subviewport.free()

func test_storyboard_split_view_clips_to_view_width() -> void:
	var camera: Node3D = Node3D.new()
	var storyboard: CameramanStoryboard = CameramanStoryboard.new()
	storyboard.split_view = 0.5
	camera.add_child(storyboard)
	add_child_autofree(camera)
	storyboard._process(0.1)
	var layer: CanvasLayer = storyboard.get_child(0) as CanvasLayer
	var clipping_control: Control = layer.get_child(0) as Control
	var viewport_width: float = camera.get_viewport().get_visible_rect().size.x
	assert_almost_eq(clipping_control.size.x, viewport_width * 0.5, 0.01)

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
