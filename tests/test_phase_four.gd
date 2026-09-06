extends GutTest

class QualityExtension extends CameramanExtension:
	var quality: float = 0.0

	func post_pipeline_stage_callback(
		_camera: Node,
		stage: CameramanCore.Stage,
		state: CameramanCameraState,
		_delta: float
	) -> void:
		if stage == CameramanCore.Stage.FINALIZE:
			state.shot_quality = quality

func _manager_scene(manager: CameramanCameraManagerBase) -> Dictionary:
	var root: Node = Node.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	brain.default_blend.style = CameramanBlendDefinition.Style.CUT
	root.add_child(output)
	output.add_child(brain)
	root.add_child(manager)
	add_child_autofree(root)
	return {"root": root, "brain": brain}

func test_clear_shot_selects_highest_quality_child() -> void:
	var manager: CameramanClearShot = CameramanClearShot.new()
	manager.priority_enabled = true
	manager.priority = 10
	var first: CameramanCamera = CameramanCamera.new()
	var second: CameramanCamera = CameramanCamera.new()
	var first_quality: QualityExtension = QualityExtension.new()
	var second_quality: QualityExtension = QualityExtension.new()
	first_quality.quality = 0.2
	second_quality.quality = 0.8
	first.add_child(first_quality)
	second.add_child(second_quality)
	manager.add_child(first)
	manager.add_child(second)
	var scene: Dictionary = _manager_scene(manager)
	var brain: CameramanBrain = scene.brain
	brain.manual_update(0.1)
	assert_eq(manager.live_child, second)

func test_manager_does_not_reparent_child_world_state() -> void:
	var manager: CameramanClearShot = CameramanClearShot.new()
	var camera: CameramanCamera = CameramanCamera.new()
	camera.position = Vector3(5.0, 3.0, 2.0)
	manager.add_child(camera)
	var scene: Dictionary = _manager_scene(manager)
	var brain: CameramanBrain = scene.brain
	var expected: Vector3 = camera.global_position
	brain.manual_update(0.1)
	brain.manual_update(0.1)
	assert_almost_eq(camera.global_position, expected, Vector3.ONE * 0.001)

func test_clear_shot_min_duration_allows_switch_after_hold() -> void:
	var manager: CameramanClearShot = CameramanClearShot.new()
	manager.min_duration = 0.5
	manager.activate_after = 0.1
	var first: CameramanCamera = CameramanCamera.new()
	var second: CameramanCamera = CameramanCamera.new()
	var first_quality: QualityExtension = QualityExtension.new()
	var second_quality: QualityExtension = QualityExtension.new()
	first_quality.quality = 0.2
	second_quality.quality = 0.8
	first.add_child(first_quality)
	second.add_child(second_quality)
	manager.add_child(first)
	manager.add_child(second)
	var scene: Dictionary = _manager_scene(manager)
	var brain: CameramanBrain = scene.brain
	brain.manual_update(0.1)
	assert_eq(manager.live_child, second)
	first_quality.quality = 0.9
	second_quality.quality = 0.1
	brain.manual_update(0.1)
	assert_eq(manager.live_child, second)
	brain.manual_update(0.5)
	assert_eq(manager.live_child, first)

func test_state_driven_switches_animation_player_with_delay() -> void:
	var manager: CameramanStateDrivenCamera = CameramanStateDrivenCamera.new()
	manager.priority_enabled = true
	manager.priority = 10
	var idle: CameramanCamera = CameramanCamera.new()
	var run: CameramanCamera = CameramanCamera.new()
	idle.name = "IdleCamera"
	run.name = "RunCamera"
	manager.add_child(idle)
	manager.add_child(run)
	var player: AnimationPlayer = AnimationPlayer.new()
	player.name = "AnimationPlayer"
	var library: AnimationLibrary = AnimationLibrary.new()
	library.add_animation("Idle", Animation.new())
	library.add_animation("Run", Animation.new())
	player.add_animation_library("", library)
	manager.add_child(player)
	var idle_instruction: CameramanStateDrivenInstruction = CameramanStateDrivenInstruction.new()
	idle_instruction.state_name = &"Idle"
	idle_instruction.camera = NodePath("IdleCamera")
	var run_instruction: CameramanStateDrivenInstruction = CameramanStateDrivenInstruction.new()
	run_instruction.state_name = &"Run"
	run_instruction.camera = NodePath("RunCamera")
	run_instruction.activate_after = 0.5
	manager.instructions = [idle_instruction, run_instruction]
	manager.animation_player_path = NodePath("AnimationPlayer")
	var scene: Dictionary = _manager_scene(manager)
	var brain: CameramanBrain = scene.brain
	player.play("Idle")
	brain.manual_update(0.1)
	assert_eq(manager.live_child, idle)
	player.play("Run")
	brain.manual_update(0.1)
	assert_eq(manager.live_child, idle)
	brain.manual_update(0.5)
	assert_eq(manager.live_child, run)

func test_state_driven_uses_live_instruction_min_duration() -> void:
	var manager: CameramanStateDrivenCamera = CameramanStateDrivenCamera.new()
	manager.priority_enabled = true
	manager.priority = 10
	var idle: CameramanCamera = CameramanCamera.new()
	var run: CameramanCamera = CameramanCamera.new()
	idle.name = "IdleCamera"
	run.name = "RunCamera"
	manager.add_child(idle)
	manager.add_child(run)
	var player: AnimationPlayer = AnimationPlayer.new()
	player.name = "AnimationPlayer"
	var library: AnimationLibrary = AnimationLibrary.new()
	library.add_animation("Idle", Animation.new())
	library.add_animation("Run", Animation.new())
	player.add_animation_library("", library)
	manager.add_child(player)
	var idle_instruction: CameramanStateDrivenInstruction = CameramanStateDrivenInstruction.new()
	idle_instruction.state_name = &"Idle"
	idle_instruction.camera = NodePath("IdleCamera")
	idle_instruction.min_duration = 2.0
	var run_instruction: CameramanStateDrivenInstruction = CameramanStateDrivenInstruction.new()
	run_instruction.state_name = &"Run"
	run_instruction.camera = NodePath("RunCamera")
	run_instruction.activate_after = 0.0
	run_instruction.min_duration = 0.0
	manager.instructions = [idle_instruction, run_instruction]
	manager.animation_player_path = NodePath("AnimationPlayer")
	var scene: Dictionary = _manager_scene(manager)
	var brain: CameramanBrain = scene.brain
	player.play("Idle")
	brain.manual_update(0.1)
	assert_eq(manager.live_child, idle)
	player.play("Run")
	brain.manual_update(0.1)
	assert_eq(manager.live_child, idle)

func test_sequencer_advances_holds_and_loops() -> void:
	var manager: CameramanSequencerCamera = CameramanSequencerCamera.new()
	manager.priority_enabled = true
	manager.priority = 10
	var first: CameramanCamera = CameramanCamera.new()
	var second: CameramanCamera = CameramanCamera.new()
	first.name = "First"
	second.name = "Second"
	manager.add_child(first)
	manager.add_child(second)
	var first_instruction: CameramanSequencerInstruction = CameramanSequencerInstruction.new()
	first_instruction.camera = NodePath("First")
	first_instruction.hold = 0.5
	var second_instruction: CameramanSequencerInstruction = CameramanSequencerInstruction.new()
	second_instruction.camera = NodePath("Second")
	second_instruction.hold = 0.5
	manager.instructions = [first_instruction, second_instruction]
	manager.loop = true
	var scene: Dictionary = _manager_scene(manager)
	var brain: CameramanBrain = scene.brain
	brain.manual_update(0.1)
	assert_eq(manager.live_child, first)
	brain.manual_update(0.5)
	assert_eq(manager.live_child, second)
	brain.manual_update(0.5)
	assert_eq(manager.live_child, first)

func test_mixing_camera_blends_weighted_midpoint() -> void:
	var manager: CameramanMixingCamera = CameramanMixingCamera.new()
	manager.priority_enabled = true
	manager.priority = 10
	var first: CameramanCamera = CameramanCamera.new()
	var second: CameramanCamera = CameramanCamera.new()
	first.position = Vector3.ZERO
	second.position = Vector3(10.0, 0.0, 0.0)
	manager.add_child(first)
	manager.add_child(second)
	manager.weights = [0.5, 0.5]
	var scene: Dictionary = _manager_scene(manager)
	scene.brain.manual_update(0.1)
	assert_almost_eq(manager.get_state().raw_position, Vector3(5.0, 0.0, 0.0), Vector3.ONE * 0.001)

func test_shot_sequence_drives_and_releases_override() -> void:
	var root: Node = Node.new()
	var output: Camera3D = Camera3D.new()
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	brain.default_blend.style = CameramanBlendDefinition.Style.CUT
	var first: CameramanCamera = CameramanCamera.new()
	var second: CameramanCamera = CameramanCamera.new()
	first.name = "First"
	second.name = "Second"
	first.priority_enabled = true
	first.priority = 1
	second.priority_enabled = true
	second.priority = 2
	var sequence: CameramanShotSequence = CameramanShotSequence.new()
	var shot: CameramanShot = CameramanShot.new()
	shot.camera = NodePath("../First")
	shot.weight = 1.0
	sequence.add_child(shot)
	root.add_child(output)
	output.add_child(brain)
	root.add_child(first)
	root.add_child(second)
	root.add_child(sequence)
	add_child_autofree(root)
	sequence.brain_path = NodePath("../Output/Brain")
	sequence._process(0.1)
	brain.manual_update(0.1)
	assert_almost_eq(brain.current_camera_state.raw_position, first.position, Vector3.ONE * 0.001)
	shot.active = false
	sequence._process(0.1)
	brain.manual_update(0.1)
	assert_eq(brain.active_virtual_camera, second)

func test_plugin_script_and_demo_scenes_load() -> void:
	assert_not_null(load("res://addons/cameraman/cameraman_plugin.gd"))
	for demo_name in [
		"third_person", "free_look", "platformer_2d", "dolly",
		"clear_shot", "split_screen", "impulse", "sequence", "state_driven"
	]:
		var scene: PackedScene = load("res://demo/%s.tscn" % demo_name)
		assert_not_null(scene)

		var instance: Node = scene.instantiate()
		add_child_autofree(instance)
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		assert_gt(get_tree().get_frame(), 0)
		var brains: Array[Node] = instance.find_children("*", "CameramanBrain", true, false)
		brains.append_array(instance.find_children("*", "CameramanBrain2D", true, false))
		assert_gt(brains.size(), 0)
		var lights: Array[Node] = instance.find_children("*", "DirectionalLight3D", true, false)
		lights.append_array(instance.find_children("*", "DirectionalLight2D", true, false))
		assert_gt(lights.size(), 0)
		for brain_node in brains:
			var brain: CameramanBrain = brain_node as CameramanBrain
			if demo_name == "sequence":
				assert_not_null(brain.current_camera_state, demo_name)
			else:
				assert_not_null(brain.active_virtual_camera, demo_name)
			if demo_name == "platformer_2d":
				await get_tree().process_frame
				await get_tree().process_frame
				var output: Camera2D = instance.get_node("OutputCamera") as Camera2D
				var player: Node2D = instance.get_node("Level/PlatformerPlayer") as Node2D
				assert_lt(output.global_position.distance_to(player.global_position), 200.0)
	assert_true(FileAccess.file_exists("res://addons/cameraman/plugin.cfg"))

func test_projectile_registers_enemy_hit() -> void:
	var root := Node3D.new()
	var enemy := CameramanDemoEnemy.new()
	enemy.position = Vector3(0.0, 1.0, -2.0)
	var projectile := CameramanDemoProjectile.new()
	projectile.position = Vector3(0.0, 1.0, 0.0)
	root.add_child(enemy)
	root.add_child(projectile)
	add_child_autofree(root)
	projectile.linear_velocity = Vector3(0.0, 0.0, -10.0)
	for _index in 24:
		await get_tree().physics_frame
	assert_eq(enemy.hit_count, 1)

func test_player_latches_camera_relative_movement_basis() -> void:
	var root := Node3D.new()
	var camera := Camera3D.new()
	camera.current = true
	var brain := CameramanBrain.new()
	brain.default_blend.style = CameramanBlendDefinition.Style.LINEAR
	brain.default_blend.time = 10.0
	var first := CameramanCamera.new()
	var second := CameramanCamera.new()
	first.priority_enabled = true
	first.priority = 2
	second.priority_enabled = true
	second.priority = 1
	second.rotation.y = PI
	var player := CameramanDemoPlayerController.new()
	player.mouse_look_enabled = false
	root.add_child(camera)
	camera.add_child(brain)
	root.add_child(first)
	root.add_child(second)
	root.add_child(player)
	add_child_autofree(root)
	Input.action_press("move_forward")
	for _index in 3:
		await get_tree().physics_frame
	var first_direction := Vector2(player.velocity.x, player.velocity.z).normalized()
	first.rotation.y = PI * 0.5
	for _index in 30:
		await get_tree().physics_frame
	var steered_direction := Vector2(player.velocity.x, player.velocity.z).normalized()
	second.priority = 3
	for _index in 30:
		await get_tree().physics_frame
	var blending_direction := Vector2(player.velocity.x, player.velocity.z).normalized()
	Input.action_release("move_forward")
	assert_lt(steered_direction.dot(first_direction), 0.5)
	assert_lt(steered_direction.x, -0.8)
	assert_true(brain.is_blending)
	assert_almost_eq(blending_direction, steered_direction, Vector2.ONE * 0.05)
