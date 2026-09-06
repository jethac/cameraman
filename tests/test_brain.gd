extends GutTest

class CounterComponent extends CameramanComponent:
	var updates: int = 0

	func stage() -> CameramanCore.Stage:
		return CameramanCore.Stage.BODY

	func mutate_camera_state(_state: CameramanCameraState, _delta: float) -> void:
		updates += 1

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

func test_override_manual_weight_is_stable_across_updates() -> void:
	var root: Node = Node.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	var first: CameramanCamera = CameramanCamera.new()
	var second: CameramanCamera = CameramanCamera.new()
	first.position = Vector3.ZERO
	second.position = Vector3(10.0, 0.0, 0.0)
	root.add_child(output)
	output.add_child(brain)
	root.add_child(first)
	root.add_child(second)
	add_child_autofree(root)
	brain.set_camera_override(-1, 100, first, second, 0.5, 0.0)
	brain.manual_update(0.1)
	var expected: Vector3 = output.global_position
	brain.manual_update(0.1)
	brain.manual_update(0.1)
	assert_almost_eq(output.global_position, expected, Vector3.ONE * 0.001)

func test_blend_events_fire_once() -> void:
	var root: Node = Node.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	brain.default_blend.time = 0.1
	var first: CameramanCamera = CameramanCamera.new()
	var second: CameramanCamera = CameramanCamera.new()
	first.priority_enabled = true
	second.priority_enabled = true
	first.priority = 1
	second.priority = 2
	root.add_child(output)
	output.add_child(brain)
	root.add_child(first)
	root.add_child(second)
	add_child_autofree(root)
	watch_signals(CameramanCore.get_events())
	brain.manual_update(0.1)
	first.priority = 3
	second.priority = 0
	brain.manual_update(0.05)
	brain.manual_update(0.1)
	assert_signal_emit_count(CameramanCore.get_events(), "blend_created", 1)
	assert_signal_emit_count(CameramanCore.get_events(), "blend_finished", 1)

func test_brains_select_disjoint_channels() -> void:
	var root: Node = Node.new()
	var output_a: Camera3D = Camera3D.new()
	var output_b: Camera3D = Camera3D.new()
	var brain_a: CameramanBrain = CameramanBrain.new()
	var brain_b: CameramanBrain = CameramanBrain.new()
	brain_a.update_method = CameramanBrain.UpdateMethod.MANUAL
	brain_b.update_method = CameramanBrain.UpdateMethod.MANUAL
	brain_a.channel_mask = 1
	brain_b.channel_mask = 2
	var camera_a: CameramanCamera = CameramanCamera.new()
	var camera_b: CameramanCamera = CameramanCamera.new()
	camera_a.output_channel = 1
	camera_b.output_channel = 2
	camera_a.priority_enabled = true
	camera_b.priority_enabled = true
	camera_a.priority = 1
	camera_b.priority = 1
	camera_a.position = Vector3(1.0, 0.0, 0.0)
	camera_b.position = Vector3(2.0, 0.0, 0.0)
	root.add_child(output_a)
	root.add_child(output_b)
	output_a.add_child(brain_a)
	output_b.add_child(brain_b)
	root.add_child(camera_a)
	root.add_child(camera_b)
	add_child_autofree(root)
	brain_a.manual_update(0.1)
	brain_b.manual_update(0.1)
	assert_eq(brain_a.active_virtual_camera, camera_a)
	assert_eq(brain_b.active_virtual_camera, camera_b)

func test_round_robin_standby_updates_one_camera_per_frame() -> void:
	var root: Node = Node.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	var live: CameramanCamera = CameramanCamera.new()
	live.priority_enabled = true
	live.priority = 10
	var standby_a: CameramanCamera = CameramanCamera.new()
	var standby_b: CameramanCamera = CameramanCamera.new()
	standby_a.standby_update = CameramanVirtualCameraBase.StandbyUpdate.ROUND_ROBIN
	standby_b.standby_update = CameramanVirtualCameraBase.StandbyUpdate.ROUND_ROBIN
	var counter_a: CounterComponent = CounterComponent.new()
	var counter_b: CounterComponent = CounterComponent.new()
	standby_a.add_child(counter_a)
	standby_b.add_child(counter_b)
	root.add_child(output)
	output.add_child(brain)
	root.add_child(live)
	root.add_child(standby_a)
	root.add_child(standby_b)
	add_child_autofree(root)
	brain.manual_update(0.1)
	var first_count: int = counter_a.updates + counter_b.updates
	brain.manual_update(0.1)
	var second_count: int = counter_a.updates + counter_b.updates
	assert_eq(first_count, 1)
	assert_eq(second_count - first_count, 1)

func test_freeze_when_blending_out_snapshots_outgoing_state() -> void:
	var root: Node = Node.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	brain.default_blend.time = 1.0
	var target: Node3D = Node3D.new()
	var first: CameramanCamera = CameramanCamera.new()
	var second: CameramanCamera = CameramanCamera.new()
	first.set_follow(target)
	first.blend_hint = CameramanCore.BlendHint.FREEZE_WHEN_BLENDING_OUT
	first.priority_enabled = true
	second.priority_enabled = true
	first.priority = 2
	second.priority = 1
	root.add_child(target)
	root.add_child(output)
	output.add_child(brain)
	root.add_child(first)
	root.add_child(second)
	add_child_autofree(root)
	brain.manual_update(0.1)
	first.priority = 0
	second.priority = 3
	brain.manual_update(0.1)
	assert_true(brain.active_blend.cam_a is CameramanFrozenSource)
	var frozen_position: Vector3 = brain.active_blend.cam_a.get_state().raw_position
	target.position = Vector3(100.0, 0.0, 0.0)
	brain.manual_update(0.1)
	assert_almost_eq(
		brain.active_blend.cam_a.get_state().raw_position,
		frozen_position,
		Vector3.ONE * 0.001
	)

func test_inherit_position_applies_before_incoming_evaluation() -> void:
	var root: Node = Node.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	brain.default_blend.time = 1.0
	var first: CameramanCamera = CameramanCamera.new()
	var second: CameramanCamera = CameramanCamera.new()
	first.priority_enabled = true
	second.priority_enabled = true
	first.priority = 2
	second.priority = 1
	first.position = Vector3(3.0, 0.0, 0.0)
	second.position = Vector3(20.0, 0.0, 0.0)
	second.blend_hint = CameramanCore.BlendHint.INHERIT_POSITION
	root.add_child(output)
	output.add_child(brain)
	root.add_child(first)
	root.add_child(second)
	add_child_autofree(root)
	brain.manual_update(0.1)
	var outgoing_position: Vector3 = first.get_state().get_final_position()
	first.priority = 0
	second.priority = 3
	brain.manual_update(0.1)
	assert_almost_eq(second.get_state().raw_position, outgoing_position, Vector3.ONE * 0.001)
