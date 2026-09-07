extends GutTest

func test_storyboard_world_space_center_y_moves_quad_down() -> void:
	var root: Node3D = Node3D.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	output.add_child(brain)
	root.add_child(output)
	var camera: CameramanCamera = CameramanCamera.new()
	camera.priority_enabled = true
	camera.priority = 1
	var storyboard: CameramanStoryboard = CameramanStoryboard.new()
	storyboard.render_mode = CameramanStoryboard.RenderMode.WORLD_SPACE
	storyboard.center = Vector2(0.5, 0.75)
	storyboard.world_distance = 2.0
	storyboard.image = ImageTexture.create_from_image(
		Image.create(16, 16, false, Image.FORMAT_RGBA8)
	)
	camera.add_child(storyboard)
	root.add_child(camera)
	add_child_autofree(root)
	brain.manual_update(0.1)
	storyboard._process(0.1)
	var quad: MeshInstance3D = storyboard.get_child(0) as MeshInstance3D
	var view_basis: Basis = output.global_basis.orthonormalized()
	var forward_point: Vector3 = output.global_position - view_basis.z * 2.0
	assert_lt(
		view_basis.y.dot(quad.global_position - forward_point),
		0.0
	)

func test_storyboard_world_space_reparents_to_output_viewport_and_frees_quad() -> void:
	var root: Node = Node.new()
	var subviewport: SubViewport = SubViewport.new()
	subviewport.size = Vector2i(320, 240)
	subviewport.own_world_3d = true
	root.add_child(subviewport)
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	output.add_child(brain)
	subviewport.add_child(output)
	var camera: CameramanCamera = CameramanCamera.new()
	camera.priority_enabled = true
	camera.priority = 1
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
	var quad: MeshInstance3D = storyboard._world_quad
	assert_eq(quad.get_viewport(), subviewport)
	storyboard.free()
	assert_false(is_instance_valid(quad))

func test_storyboard_priority_follows_brain_added_later() -> void:
	var root: Node3D = Node3D.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	var camera: CameramanCamera = CameramanCamera.new()
	var storyboard: CameramanStoryboard = CameramanStoryboard.new()
	camera.add_child(storyboard)
	root.add_child(camera)
	output.add_child(brain)
	root.add_child(output)
	add_child_autofree(root)
	await get_tree().process_frame
	assert_eq(brain.process_priority, 1000)
	assert_eq(storyboard.process_priority, brain.process_priority + 1)
