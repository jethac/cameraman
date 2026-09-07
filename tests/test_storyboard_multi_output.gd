extends GutTest

func _make_fixture(mode: CameramanStoryboard.RenderMode) -> Dictionary:
	var root: Node = Node.new()
	var viewport_a: SubViewport = SubViewport.new()
	viewport_a.size = Vector2i(320, 240)
	viewport_a.own_world_3d = true
	var viewport_b: SubViewport = SubViewport.new()
	viewport_b.size = Vector2i(320, 240)
	viewport_b.own_world_3d = true
	root.add_child(viewport_a)
	root.add_child(viewport_b)
	var output_a: Camera3D = Camera3D.new()
	var output_b: Camera3D = Camera3D.new()
	var brain_a: CameramanBrain = CameramanBrain.new()
	var brain_b: CameramanBrain = CameramanBrain.new()
	brain_a.update_method = CameramanBrain.UpdateMethod.MANUAL
	brain_b.update_method = CameramanBrain.UpdateMethod.MANUAL
	output_a.add_child(brain_a)
	output_b.add_child(brain_b)
	viewport_a.add_child(output_a)
	viewport_b.add_child(output_b)
	var camera: CameramanCamera = CameramanCamera.new()
	camera.priority_enabled = true
	camera.priority = 1
	var storyboard: CameramanStoryboard = CameramanStoryboard.new()
	storyboard.render_mode = mode
	storyboard.image = ImageTexture.create_from_image(
		Image.create(16, 16, false, Image.FORMAT_RGBA8)
	)
	camera.add_child(storyboard)
	root.add_child(camera)
	add_child_autofree(root)
	return {
		"brain_a": brain_a,
		"brain_b": brain_b,
		"storyboard": storyboard,
		"viewport_a": viewport_a,
		"viewport_b": viewport_b,
	}

func _update_fixture(fixture: Dictionary) -> void:
	(fixture["brain_a"] as CameramanBrain).manual_update(0.1)
	(fixture["brain_b"] as CameramanBrain).manual_update(0.1)
	(fixture["storyboard"] as CameramanStoryboard)._process(0.1)

func test_storyboard_renders_one_quad_per_live_brain() -> void:
	var fixture: Dictionary = _make_fixture(CameramanStoryboard.RenderMode.WORLD_SPACE)
	var brain_a: CameramanBrain = fixture["brain_a"]
	var brain_b: CameramanBrain = fixture["brain_b"]
	brain_a.storyboard_render_layers = 2
	brain_b.storyboard_render_layers = 4
	_update_fixture(fixture)
	var storyboard: CameramanStoryboard = fixture["storyboard"]
	var views: Array = storyboard.get_output_views()
	assert_eq(views.size(), 2)
	var view_a: CameramanStoryboard.OutputView
	var view_b: CameramanStoryboard.OutputView
	for view_value in views:
		var view: CameramanStoryboard.OutputView = view_value
		if view.brain == brain_a:
			view_a = view
		elif view.brain == brain_b:
			view_b = view
	assert_eq(view_a.world_quad.get_viewport(), fixture["viewport_a"])
	assert_eq(view_b.world_quad.get_viewport(), fixture["viewport_b"])
	assert_eq(view_a.world_quad.layers, 2)
	assert_eq(view_b.world_quad.layers, 4)
	assert_true(view_a.world_quad.visible)
	assert_true(view_b.world_quad.visible)

func test_storyboard_camera_space_binds_each_output_viewport() -> void:
	var fixture: Dictionary = _make_fixture(
		CameramanStoryboard.RenderMode.SCREEN_SPACE_CAMERA
	)
	_update_fixture(fixture)
	var views: Array = (fixture["storyboard"] as CameramanStoryboard).get_output_views()
	assert_eq(views.size(), 2)
	for view_value in views:
		var view: CameramanStoryboard.OutputView = view_value
		var expected: Viewport = (
			fixture["viewport_a"] if view.brain == fixture["brain_a"]
			else fixture["viewport_b"]
		)
		assert_eq(view.layer.custom_viewport, expected)

func test_storyboard_recreates_screen_nodes_without_leaking_layer() -> void:
	var fixture: Dictionary = _make_fixture(
		CameramanStoryboard.RenderMode.SCREEN_SPACE_CAMERA
	)
	(fixture["viewport_b"] as SubViewport).free()
	(fixture["brain_a"] as CameramanBrain).manual_update(0.1)
	var storyboard: CameramanStoryboard = fixture["storyboard"]
	storyboard._process(0.1)
	var view: CameramanStoryboard.OutputView = storyboard.get_output_views()[0]
	view.texture_rect.free()
	storyboard._process(0.1)
	assert_eq(storyboard.get_child_count(), 1)
	assert_true(is_instance_valid(view.layer))
	assert_true(is_instance_valid(view.texture_rect))

func test_storyboard_overlay_uses_single_view() -> void:
	var fixture: Dictionary = _make_fixture(
		CameramanStoryboard.RenderMode.SCREEN_SPACE_OVERLAY
	)
	_update_fixture(fixture)
	assert_eq((fixture["storyboard"] as CameramanStoryboard).get_output_views().size(), 1)

func test_storyboard_drops_view_when_brain_leaves() -> void:
	var fixture: Dictionary = _make_fixture(CameramanStoryboard.RenderMode.WORLD_SPACE)
	_update_fixture(fixture)
	var storyboard: CameramanStoryboard = fixture["storyboard"]
	var brain_a: CameramanBrain = fixture["brain_a"]
	var brain_b: CameramanBrain = fixture["brain_b"]
	var brain_b_quad: MeshInstance3D
	for view_value in storyboard.get_output_views():
		var view: CameramanStoryboard.OutputView = view_value
		if view.brain == brain_b:
			brain_b_quad = view.world_quad
	var output_b: Node = brain_b.get_parent()
	output_b.remove_child(brain_b)
	brain_b.free()
	storyboard._process(0.1)
	var views: Array = storyboard.get_output_views()
	assert_eq(views.size(), 1)
	assert_eq(views[0].brain, brain_a)
	assert_false(is_instance_valid(brain_b_quad))

func test_storyboard_teardown_ignores_freed_output_viewport() -> void:
	var fixture: Dictionary = _make_fixture(CameramanStoryboard.RenderMode.WORLD_SPACE)
	_update_fixture(fixture)
	var storyboard: CameramanStoryboard = fixture["storyboard"]
	(fixture["viewport_b"] as SubViewport).free()
	storyboard.free()
	assert_false(is_instance_valid(storyboard))

func test_storyboard_keeps_live_view_after_output_viewport_frees() -> void:
	var fixture: Dictionary = _make_fixture(CameramanStoryboard.RenderMode.WORLD_SPACE)
	_update_fixture(fixture)
	var storyboard: CameramanStoryboard = fixture["storyboard"]
	var brain_a: CameramanBrain = fixture["brain_a"]
	(fixture["viewport_b"] as SubViewport).free()
	storyboard._process(0.1)
	var views: Array = storyboard.get_output_views()
	assert_eq(views.size(), 1)
	assert_eq(views[0].brain, brain_a)
	assert_true(is_instance_valid(views[0].world_quad))
	assert_eq(views[0].world_quad.get_viewport(), fixture["viewport_a"])
