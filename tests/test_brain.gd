extends GutTest

func test_brain_selects_priority_and_recent_activation() -> void:
	var root: Node = Node.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	var first: CameramanCamera = CameramanCamera.new()
	var second: CameramanCamera = CameramanCamera.new()
	first.priority = 4
	second.priority = 4
	root.add_child(output)
	output.add_child(brain)
	root.add_child(first)
	root.add_child(second)
	add_child_autofree(root)
	first.prioritize()
	second.prioritize()
	brain.manual_update(0.1)
	assert_eq(brain.active_virtual_camera, second)

func test_brain_writes_camera_and_cut_event() -> void:
	var root: Node = Node.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	brain.default_blend.style = CameramanBlendDefinition.Style.CUT
	var camera: CameramanCamera = CameramanCamera.new()
	camera.position = Vector3(1.0, 2.0, 3.0)
	root.add_child(output)
	output.add_child(brain)
	root.add_child(camera)
	add_child_autofree(root)
	watch_signals(brain)
	brain.manual_update(0.1)
	assert_eq(brain.active_virtual_camera, camera)
	assert_signal_emitted(brain, "camera_cut")
	assert_almost_eq(output.global_position, camera.position, Vector3.ONE * 0.001)

func test_brain_override_precedes_priority() -> void:
	var root: Node = Node.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	var preferred: CameramanCamera = CameramanCamera.new()
	var override_camera: CameramanCamera = CameramanCamera.new()
	preferred.priority = 10
	override_camera.priority = 1
	root.add_child(brain)
	root.add_child(preferred)
	root.add_child(override_camera)
	add_child_autofree(root)
	brain.set_camera_override(-1, 100, null, override_camera, 1.0, 0.0)
	brain.manual_update(0.1)
	assert_eq(brain.active_virtual_camera, override_camera)

func test_blend_interruption_keeps_current_position_continuous() -> void:
	var root: Node = Node.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	brain.default_blend.time = 1.0
	var first: CameramanCamera = CameramanCamera.new()
	var second: CameramanCamera = CameramanCamera.new()
	var third: CameramanCamera = CameramanCamera.new()
	first.position = Vector3.ZERO
	second.position = Vector3(10.0, 0.0, 0.0)
	third.position = Vector3(-10.0, 0.0, 0.0)
	first.priority = 1
	second.priority = 2
	third.priority = 3
	root.add_child(output)
	output.add_child(brain)
	root.add_child(first)
	root.add_child(second)
	root.add_child(third)
	add_child_autofree(root)
	brain.manual_update(0.1)
	third.priority = 0
	brain.manual_update(0.25)
	brain.manual_update(0.01)
	var before_interrupt: Vector3 = output.global_position
	second.priority = 0
	third.priority = 3
	brain.manual_update(0.01)
	var after_interrupt: Vector3 = output.global_position
	assert_lt(before_interrupt.distance_to(after_interrupt), 1.0)
