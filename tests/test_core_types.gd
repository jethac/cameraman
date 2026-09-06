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

func test_blend_curves_have_expected_endpoints() -> void:
	for style in CameramanBlendDefinition.Style.values():
		var definition: CameramanBlendDefinition = CameramanBlendDefinition.new()
		definition.style = style
		var curve: Curve = definition.get_curve()
		assert_almost_eq(curve.sample(0.0), 0.0 if style != CameramanBlendDefinition.Style.CUT else 1.0, 0.001)
		assert_almost_eq(curve.sample(1.0), 1.0 if style != CameramanBlendDefinition.Style.CUT else 1.0, 0.001)

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
