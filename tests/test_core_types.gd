extends GutTest

func test_lens_lerps_in_focal_length_space() -> void:
	var wide: CameramanLens = CameramanLens.preset_24mm()
	var tele: CameramanLens = CameramanLens.preset_50mm()
	var middle: CameramanLens = wide.lerp(tele, 0.5)
	var expected_focal: float = lerpf(24.0, 50.0, 0.5)
	var actual_focal: float = 12.0 / tan(deg_to_rad(middle.fov_degrees) * 0.5)
	assert_almost_eq(actual_focal, expected_focal, 0.01)

func test_damper_reaches_ninety_nine_percent_at_damp_time() -> void:
	var value: float = CameramanDamper.damp(1.0, 1.0, 1.0)
	assert_gte(value, 0.99)

func test_zero_damp_is_immediate() -> void:
	assert_almost_eq(CameramanDamper.damp(1.0, 0.0, 0.1), 1.0, 0.001)

func test_blend_curves_have_expected_endpoints() -> void:
	for style in CameramanBlendDefinition.Style.values():
		var definition: CameramanBlendDefinition = CameramanBlendDefinition.new()
		definition.style = style
		var curve: Curve = definition.get_curve()
		assert_almost_eq(curve.sample(0.0), 0.0 if style != CameramanBlendDefinition.Style.CUT else 1.0, 0.001)
		assert_almost_eq(curve.sample(1.0), 1.0 if style != CameramanBlendDefinition.Style.CUT else 1.0, 0.001)

func test_blend_completion_samples_final_state() -> void:
	var root: Node = Node.new()
	var camera_a: CameramanCamera = CameramanCamera.new()
	var camera_b: CameramanCamera = CameramanCamera.new()
	camera_a.position = Vector3.ZERO
	camera_b.position = Vector3(10.0, 0.0, 0.0)
	root.add_child(camera_a)
	root.add_child(camera_b)
	add_child_autofree(root)
	var definition: CameramanBlendDefinition = CameramanBlendDefinition.new()
	definition.style = CameramanBlendDefinition.Style.LINEAR
	definition.time = 1.0
	var blend: CameramanBlend = CameramanBlend.new(camera_a, camera_b, definition)
	for _index in 4:
		blend.update_state(Vector3.UP, 0.25)
	assert_true(blend.is_complete())
	assert_almost_eq(blend.get_state().raw_position, camera_b.get_state().raw_position, Vector3.ONE * 0.001)

func test_blend_definition_invalidates_cached_curve() -> void:
	var definition: CameramanBlendDefinition = CameramanBlendDefinition.new()
	definition.style = CameramanBlendDefinition.Style.LINEAR
	var linear: Curve = definition.get_curve()
	definition.style = CameramanBlendDefinition.Style.CUT
	var cut: Curve = definition.get_curve()
	assert_almost_eq(linear.sample(0.0), 0.0, 0.001)
	assert_almost_eq(cut.sample(0.0), 1.0, 0.001)
	definition.style = CameramanBlendDefinition.Style.EASE_IN
	var ease_in: Curve = definition.get_curve()
	assert_lt(ease_in.sample(0.5), linear.sample(0.5))
	var custom: Curve = Curve.new()
	custom.add_point(Vector2(0.0, 0.0))
	custom.add_point(Vector2(1.0, 0.0))
	definition.custom_curve = custom
	definition.style = CameramanBlendDefinition.Style.CUSTOM
	assert_almost_eq(definition.get_curve().sample(1.0), 0.0, 0.001)

func test_ease_in_out_midpoint_is_half() -> void:
	var definition: CameramanBlendDefinition = CameramanBlendDefinition.new()
	definition.style = CameramanBlendDefinition.Style.EASE_IN_OUT
	assert_almost_eq(definition.get_curve().sample(0.5), 0.5, 0.01)

func test_state_lerp_supports_spherical_and_cylindrical_hints() -> void:
	var from_state: CameramanCameraState = CameramanCameraState.create_default()
	from_state.raw_position = Vector3(0.0, 0.0, 5.0)
	from_state.reference_look_at = Vector3.ZERO
	var to_state: CameramanCameraState = CameramanCameraState.create_default()
	to_state.raw_position = Vector3(5.0, 5.0, 0.0)
	to_state.reference_look_at = Vector3.ZERO
	from_state.blend_hint = CameramanCore.BlendHint.SPHERICAL_POSITION
	to_state.blend_hint = CameramanCore.BlendHint.SPHERICAL_POSITION
	var spherical: CameramanCameraState = CameramanCameraState.lerp(from_state, to_state, 0.5)
	assert_almost_eq(spherical.raw_position.length(), 6.0355, 0.01)
	from_state.blend_hint = CameramanCore.BlendHint.CYLINDRICAL_POSITION
	to_state.blend_hint = CameramanCore.BlendHint.CYLINDRICAL_POSITION
	var cylindrical: CameramanCameraState = CameramanCameraState.lerp(from_state, to_state, 0.5)
	assert_almost_eq(cylindrical.raw_position.y, 2.5, 0.01)

func test_state_lerp_supports_screen_space_targets_and_custom_blendables() -> void:
	var from_state: CameramanCameraState = CameramanCameraState.create_default()
	from_state.raw_position = Vector3(0.0, 0.0, 5.0)
	from_state.reference_look_at = Vector3.ZERO
	var to_state: CameramanCameraState = CameramanCameraState.create_default()
	to_state.raw_position = Vector3(0.0, 0.0, 5.0)
	to_state.reference_look_at = Vector3(1.0, 0.0, 0.0)
	from_state.blend_hint = CameramanCore.BlendHint.SCREEN_SPACE_AIM_WHEN_TARGETS_DIFFER
	to_state.blend_hint = CameramanCore.BlendHint.SCREEN_SPACE_AIM_WHEN_TARGETS_DIFFER
	var marker_a: RefCounted = RefCounted.new()
	var marker_b: RefCounted = RefCounted.new()
	from_state.add_custom_blendable(marker_a, 1.0)
	to_state.add_custom_blendable(marker_b, 1.0)
	var result: CameramanCameraState = CameramanCameraState.lerp(from_state, to_state, 0.5)
	assert_eq(result.custom_blendables.size(), 2)
	assert_almost_eq(float(result.custom_blendables[0]["weight"]), 0.5, 0.001)
	assert_true(result.has_look_at())

func test_override_and_solo_camera_selection() -> void:
	var camera_a: CameramanCamera = CameramanCamera.new()
	var camera_b: CameramanCamera = CameramanCamera.new()
	camera_a.priority = 1
	camera_b.priority = 2
	var root: Node = Node.new()
	add_child_autofree(root)
	root.add_child(camera_a)
	root.add_child(camera_b)
	assert_eq(CameramanCore.get_registry().get_top_camera(1, root), camera_b)
	CameramanCore.solo_camera = camera_a
	assert_eq(CameramanCore.solo_camera, camera_a)
	CameramanCore.solo_camera = null

func test_blender_settings_exact_match_wins_and_ties_keep_first() -> void:
	var settings: CameramanBlenderSettings = CameramanBlenderSettings.new()
	var any_definition: CameramanBlendDefinition = CameramanBlendDefinition.new()
	any_definition.time = 1.0
	var exact_definition: CameramanBlendDefinition = CameramanBlendDefinition.new()
	exact_definition.time = 2.0
	var second_exact_definition: CameramanBlendDefinition = CameramanBlendDefinition.new()
	second_exact_definition.time = 3.0
	var any_blend: CameramanCustomBlend = CameramanCustomBlend.new()
	any_blend.definition = any_definition
	var exact_blend: CameramanCustomBlend = CameramanCustomBlend.new()
	exact_blend.from_name = "A"
	exact_blend.to_name = "B"
	exact_blend.definition = exact_definition
	var second_exact: CameramanCustomBlend = CameramanCustomBlend.new()
	second_exact.from_name = "A"
	second_exact.to_name = "B"
	second_exact.definition = second_exact_definition
	settings.custom_blends = [any_blend, exact_blend, second_exact]
	assert_eq(settings.get_blend_for("A", "B", CameramanBlendDefinition.new()), exact_definition)

func test_update_tracker_classifies_physics_motion() -> void:
	var target: Node3D = Node3D.new()
	add_child_autofree(target)
	var tracker: CameramanUpdateTracker = CameramanUpdateTracker.new()
	tracker.record_process(target)
	target.position.x = 1.0
	tracker.record_physics(target)
	tracker.record_process(target)
	assert_true(tracker.is_physics_driven(target))
	target.position.x = 2.0
	tracker.record_process(target)
	assert_false(tracker.is_physics_driven(target))

func test_screen_space_aim_uses_interpolated_local_direction() -> void:
	var from: CameramanCameraState = CameramanCameraState.create_default()
	from.raw_position = Vector3.ZERO
	from.reference_look_at = Vector3(0.0, 0.0, -10.0)
	var to: CameramanCameraState = CameramanCameraState.create_default()
	to.raw_position = Vector3.ZERO
	to.raw_orientation = Quaternion(Vector3.UP, 0.35)
	to.reference_look_at = to.raw_orientation * Vector3(1.0, 0.0, -10.0)
	for weight in [0.0, 0.5, 1.0]:
		var state: CameramanCameraState = CameramanCameraState.lerp(from, to, weight)
		var local_direction: Vector3 = state.raw_orientation.inverse() * (
			state.reference_look_at - state.raw_position
		)
		var from_screen: Vector2 = CameramanCameraState._screen_offset(
			from,
			from.reference_look_at
		)
		var to_screen: Vector2 = CameramanCameraState._screen_offset(to, to.reference_look_at)
		var expected: Vector3 = CameramanCameraState._screen_direction(
			from_screen.lerp(to_screen, weight),
			state.lens
		)
		assert_almost_eq(local_direction.normalized(), expected, Vector3.ONE * 0.001)

func test_orthographic_screen_offset_uses_half_height_and_aspect() -> void:
	var previous_aspect_ratio: float = CameramanCameraState.aspect_ratio
	CameramanCameraState.aspect_ratio = 2.0
	var state: CameramanCameraState = CameramanCameraState.create_default()
	state.lens.mode_override = CameramanLens.Mode.ORTHOGRAPHIC
	state.lens.orthographic_size = 5.0
	state.raw_position = Vector3.ZERO
	state.raw_orientation = Quaternion.IDENTITY
	assert_almost_eq(
		CameramanCameraState._screen_offset(state, Vector3(10.0, 5.0, 0.0)),
		Vector2.ONE,
		Vector2.ONE * 0.001
	)
	assert_almost_eq(
		CameramanComposerMath.project_screen_offset(
			state.raw_position,
			state.raw_orientation,
			Vector3(10.0, 5.0, 0.0),
			state.lens
		),
		Vector2.ONE,
		Vector2.ONE * 0.001
	)
	assert_almost_eq(
		CameramanCameraState._screen_direction(Vector2.ONE, state.lens),
		Vector3(2.0, 1.0, -1.0).normalized(),
		Vector3.ONE * 0.001
	)
	CameramanCameraState.aspect_ratio = previous_aspect_ratio

func test_cylindrical_hint_uses_reference_up_axis() -> void:
	var from: CameramanCameraState = CameramanCameraState.create_default(Vector3(1.0, 0.0, 0.0))
	from.reference_look_at = Vector3.ZERO
	from.raw_position = Vector3(0.0, 0.0, 2.0)
	from.blend_hint = CameramanCore.BlendHint.CYLINDRICAL_POSITION
	var to: CameramanCameraState = CameramanCameraState.create_default(Vector3(1.0, 0.0, 0.0))
	to.reference_look_at = Vector3.ZERO
	to.raw_position = Vector3(0.0, 4.0, 0.0)
	to.blend_hint = CameramanCore.BlendHint.CYLINDRICAL_POSITION
	var result: CameramanCameraState = CameramanCameraState.lerp(from, to, 0.5)
	assert_almost_eq(result.raw_position.x, 0.0, 0.001)
