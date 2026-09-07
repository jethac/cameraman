extends GutTest

func test_brain_exit_clears_storyboard_camera_liveness() -> void:
	var root: Node3D = Node3D.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	var camera: CameramanCamera = CameramanCamera.new()
	camera.priority_enabled = true
	camera.priority = 1
	var storyboard: CameramanStoryboard = CameramanStoryboard.new()
	storyboard.image = ImageTexture.create_from_image(
		Image.create(8, 8, false, Image.FORMAT_RGBA8)
	)
	camera.add_child(storyboard)
	output.add_child(brain)
	root.add_child(output)
	root.add_child(camera)
	add_child_autofree(root)
	brain.manual_update(0.1)
	storyboard._process(0.1)
	var texture_rect: TextureRect = (
		storyboard.get_child(0).get_child(0).get_child(0) as TextureRect
	)
	assert_true(CameramanCore.is_live(camera))
	assert_true(texture_rect.visible)
	output.remove_child(brain)
	await get_tree().process_frame
	storyboard._process(0.1)
	assert_false(CameramanCore.is_live(camera))
	assert_false(texture_rect.visible)
	assert_false(camera.get_meta("cameraman_mute_camera", false))
	brain.free()

func test_brain_exit_preserves_camera_liveness_of_other_brain() -> void:
	var root: Node3D = Node3D.new()
	var output_one: Camera3D = Camera3D.new()
	var output_two: Camera3D = Camera3D.new()
	var brain_one: CameramanBrain = CameramanBrain.new()
	var brain_two: CameramanBrain = CameramanBrain.new()
	brain_one.update_method = CameramanBrain.UpdateMethod.MANUAL
	brain_two.update_method = CameramanBrain.UpdateMethod.MANUAL
	var camera: CameramanCamera = CameramanCamera.new()
	camera.priority_enabled = true
	camera.priority = 1
	output_one.add_child(brain_one)
	output_two.add_child(brain_two)
	root.add_child(output_one)
	root.add_child(output_two)
	root.add_child(camera)
	add_child_autofree(root)
	brain_one.manual_update(0.1)
	brain_two.manual_update(0.1)
	assert_true(CameramanCore.is_live(camera))
	output_one.remove_child(brain_one)
	assert_true(CameramanCore.is_live(camera))
	brain_one.free()
