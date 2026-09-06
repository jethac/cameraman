class_name CameramanDemoScene
extends Node

@export var demo_kind: String = "third_person"
@export var is_2d: bool = false
@export var demo_autopilot: bool = false

var _demo_time: float = 0.0
var _player: CharacterBody3D
var _platformer_player: CameramanDemoPlatformerPlayer
var _brain: CameramanBrain
var _label: Label
var _autopilot: bool = false
var _impulse_source: CameramanImpulseSource
var _sequence: CameramanSequencerCamera
var _sequence_player: AnimationPlayer
var _state_player: AnimationPlayer

func _ready() -> void:
	_autopilot = demo_autopilot or "--autopilot" in OS.get_cmdline_user_args()
	if is_2d:
		_create_2d_demo()
	else:
		_create_3d_demo()
	_add_hud()

func _process(delta: float) -> void:
	_demo_time += delta
	if _autopilot and (
		_demo_time < (3.6 if demo_kind == "clear_shot" else 2.0)
	):
		if demo_kind == "clear_shot":
			if _demo_time < 1.5:
				Input.action_press("move_right")
				Input.action_release("move_forward")
			elif _demo_time < 2.4:
				Input.action_release("move_right")
				Input.action_press("move_forward")
			else:
				Input.action_release("move_forward")
				Input.action_press("move_left")
		else:
			Input.action_press("move_forward")
		if demo_kind == "third_person" or demo_kind == "free_look":
			var motion: InputEventMouseMotion = InputEventMouseMotion.new()
			motion.relative = Vector2(4.0, 0.0)
			Input.parse_input_event(motion)
	else:
		Input.action_release("move_forward")
		Input.action_release("move_left")
		Input.action_release("move_right")
	if demo_kind == "impulse" and fmod(_demo_time, 4.0) < delta and _impulse_source != null:
		_impulse_source.generate_impulse()
	if demo_kind == "state_driven" and _state_player != null:
		_state_player.play("idle" if fmod(_demo_time, 6.0) < 3.0 else "run")
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo:
		if key_event.keycode == KEY_ESCAPE:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				get_tree().change_scene_to_file("res://demo/main_menu.tscn")
		elif key_event.keycode == KEY_SPACE and demo_kind == "impulse" and _impulse_source != null:
			_impulse_source.generate_impulse()
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _create_3d_demo() -> void:
	_add_environment()
	if demo_kind == "split_screen":
		_create_split_screen()
		return
	_create_ground()
	_player = _create_player()
	_player.mouse_look_enabled = demo_kind == "third_person"
	var output: Camera3D = Camera3D.new()
	output.name = "OutputCamera"
	add_child(output)
	_brain = _create_brain(output, 1)
	match demo_kind:
		"clear_shot":
			_create_clear_shot(_player)
		"state_driven":
			_create_state_driven(_player)
		"sequence":
			_create_sequence(_player)
		_:
			var camera: CameramanCamera = _make_camera(
				demo_kind.capitalize(),
				_player,
				demo_kind == "dolly"
			)
			add_child(camera)
			if demo_kind == "dolly":
				_create_dolly_path(camera, _player)
			elif demo_kind == "impulse":
				_create_impulse_setup(camera)

func _create_brain(output: Node, channel: int) -> CameramanBrain:
	var brain: CameramanBrain = CameramanBrain.new()
	brain.name = "Brain"
	brain.channel_mask = channel
	brain.update_method = CameramanBrain.UpdateMethod.PROCESS
	brain.show_debug_text = true
	brain.show_camera_frustum = false
	output.add_child(brain)
	return brain

func _add_environment() -> void:
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	light.shadow_enabled = true
	light.light_energy = 1.2
	add_child(light)
	var environment: WorldEnvironment = WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	var sky: Sky = Sky.new()
	var material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	material.sky_top_color = Color("#18355c")
	material.sky_horizon_color = Color("#8fc4dd")
	material.ground_bottom_color = Color("#18202b")
	material.ground_horizon_color = Color("#718b9a")
	sky.sky_material = material
	environment.environment = Environment.new()
	environment.environment.sky = sky
	environment.environment.background_mode = Environment.BG_SKY
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.environment.ambient_light_energy = 0.7
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(environment)

func _create_ground() -> void:
	var ground: StaticBody3D = StaticBody3D.new()
	ground.name = "Ground"
	add_child(ground)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(40.0, 0.4, 40.0)
	mesh.mesh = box
	mesh.position.y = -0.2
	mesh.material_override = _material(Color("#26384a"))
	ground.add_child(mesh)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = box.size
	collision.shape = shape
	collision.position.y = -0.2
	ground.add_child(collision)
	for index in range(12):
		var angle: float = TAU * float(index) / 12.0
		var pillar: MeshInstance3D = MeshInstance3D.new()
		var pillar_mesh: BoxMesh = BoxMesh.new()
		pillar_mesh.size = Vector3(0.8, 2.5 + float(index % 3), 0.8)
		pillar.mesh = pillar_mesh
		pillar.position = Vector3(cos(angle) * 12.0, pillar_mesh.size.y * 0.5, sin(angle) * 12.0)
		pillar.material_override = _material(Color.from_hsv(float(index) / 12.0, 0.7, 0.95))
		add_child(pillar)

func _create_player() -> CharacterBody3D:
	var player: CameramanDemoPlayerController = CameramanDemoPlayerController.new()
	player.name = "Player"
	player.position = Vector3(0.0, 1.0, 0.0)
	add_child(player)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = "RedCapsule"
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = 0.45
	capsule.height = 1.8
	mesh.mesh = capsule
	mesh.material_override = _material(Color("#e44747"))
	player.add_child(mesh)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.radius = capsule.radius
	shape.height = capsule.height
	collision.shape = shape
	player.add_child(collision)
	var nose: MeshInstance3D = MeshInstance3D.new()
	nose.name = "FacingNose"
	var nose_mesh: BoxMesh = BoxMesh.new()
	nose_mesh.size = Vector3(0.24, 0.24, 0.5)
	nose.mesh = nose_mesh
	nose.position = Vector3(0.0, 0.35, -0.5)
	nose.material_override = _material(Color("#2387e8"))
	player.add_child(nose)
	var pivot: Node3D = Node3D.new()
	pivot.name = "PitchPivot"
	pivot.position.y = 0.55
	player.add_child(pivot)
	return player

func _make_camera(camera_name: String, target: Node3D, dolly: bool = false) -> CameramanCamera:
	var camera: CameramanCamera = CameramanCamera.new()
	camera.name = camera_name
	camera.priority_enabled = true
	camera.priority = 10
	camera.tracking_target = target
	camera.look_at_target = target
	if dolly:
		var spline: CameramanSplineDolly = CameramanSplineDolly.new()
		spline.name = "SplineDolly"
		spline.follow_target = target
		spline.camera_rotation = CameramanSplineDolly.CameraRotation.FOLLOW_TARGET_NO_ROLL
		spline.position_units = CameramanSplineDolly.PositionUnits.NORMALIZED
		spline.automatic_dolly.enabled = true
		spline.automatic_dolly.mode = CameramanSplineAutoDolly.Mode.FIXED_SPEED
		spline.automatic_dolly.speed = 0.12
		spline.angular_damping = 0.2
		camera.add_child(spline)
	elif demo_kind == "free_look":
		var orbital: CameramanOrbitalFollow = CameramanOrbitalFollow.new()
		orbital.name = "OrbitalFollow"
		orbital.follow_target = target
		orbital.orbit_style = CameramanOrbitalFollow.OrbitStyle.THREE_RING
		orbital.top_height = 4.0
		orbital.top_radius = 1.5
		orbital.center_height = 2.0
		orbital.center_radius = 5.0
		orbital.bottom_height = -1.0
		orbital.bottom_radius = 4.0
		orbital.horizontal_axis.recentering_enabled = true
		orbital.horizontal_axis.recentering_wait = 2.0
		orbital.recentering_target = CameramanOrbitalFollow.RecenteringTarget.TRACKING_TARGET_FORWARD
		camera.add_child(orbital)
		var controller: CameramanInputAxisController = CameramanInputAxisController.new()
		controller.name = "InputAxisController"
		camera.add_child(controller)
		_configure_input_controller(controller)
	elif demo_kind == "third_person":
		var third_person: CameramanThirdPersonFollow = CameramanThirdPersonFollow.new()
		third_person.name = "ThirdPersonFollow"
		third_person.follow_target = target
		third_person.shoulder_offset = Vector3(0.5, 1.5, 0.0)
		third_person.camera_distance = 4.0
		third_person.vertical_arm_length = 0.4
		third_person.damping = Vector3.ONE * 0.2
		camera.add_child(third_person)
		camera.blend_hint |= CameramanCore.BlendHint.INHERIT_POSITION
	else:
		var follow: CameramanFollow = CameramanFollow.new()
		follow.name = "Follow"
		follow.follow_target = target
		follow.follow_offset = Vector3(0.0, 2.5, 6.0)
		follow.position_damping = Vector3.ONE * 0.2
		camera.add_child(follow)
	var composer: CameramanRotationComposer = CameramanRotationComposer.new()
	composer.name = "RotationComposer"
	composer.composition.dead_zone_enabled = true
	composer.composition.dead_zone_size = Vector2(0.7, 0.7)
	composer.damping = Vector2.ONE * 0.15
	camera.add_child(composer)
	var look_at: CameramanHardLookAt = CameramanHardLookAt.new()
	look_at.name = "ShowcaseLookAt"
	camera.add_child(look_at)
	return camera

func _configure_input_controller(controller: CameramanInputAxisController) -> void:
	controller.synchronize_controllers()
	var horizontal: CameramanInputAxisControl = controller.get_controller("horizontal")
	if horizontal != null:
		horizontal.input_action_negative = &"look_left"
		horizontal.input_action_positive = &"look_right"
		horizontal.mouse_motion_axis = CameramanInputAxisControl.MouseMotionAxis.X
		horizontal.gain = 0.08
	var vertical: CameramanInputAxisControl = controller.get_controller("vertical")
	if vertical != null:
		vertical.input_action_negative = &"look_down"
		vertical.input_action_positive = &"look_up"
		vertical.mouse_motion_axis = CameramanInputAxisControl.MouseMotionAxis.Y
		vertical.gain = 0.08
		vertical.invert = true

func _create_dolly_path(camera: CameramanCamera, _target: Node3D) -> void:
	var path: Path3D = Path3D.new()
	path.name = "DollyPath"
	var curve: Curve3D = Curve3D.new()
	curve.add_point(Vector3(-12.0, 4.0, 8.0))
	curve.add_point(Vector3(-6.0, 2.5, -4.0))
	curve.add_point(Vector3(0.0, 5.0, -10.0))
	curve.add_point(Vector3(8.0, 3.0, -2.0))
	curve.add_point(Vector3(12.0, 4.0, 8.0))
	path.curve = curve
	add_child(path)
	var spline: CameramanSplineDolly = camera.get_node("SplineDolly") as CameramanSplineDolly
	spline.spline = path
	_draw_path(curve)

func _draw_path(curve: Curve3D) -> void:
	for index in range(curve.point_count - 1):
		var start: Vector3 = curve.get_point_position(index)
		var end: Vector3 = curve.get_point_position(index + 1)
		var marker: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(0.18, 0.18, start.distance_to(end))
		marker.mesh = mesh
		marker.position = (start + end) * 0.5
		add_child(marker)
		marker.look_at(end, Vector3.UP)
		marker.material_override = _material(Color("#f4d35e"))

func _create_clear_shot(target: Node3D) -> void:
	var wall: StaticBody3D = StaticBody3D.new()
	wall.name = "OccludingWall"
	add_child(wall)
	var wall_mesh: MeshInstance3D = MeshInstance3D.new()
	var wall_box: BoxMesh = BoxMesh.new()
	wall_box.size = Vector3(5.0, 4.0, 0.8)
	wall_mesh.mesh = wall_box
	wall_mesh.position = Vector3(0.0, 2.0, 1.0)
	wall_mesh.material_override = _material(Color("#8b4a3c"))
	wall.add_child(wall_mesh)
	var wall_collision: CollisionShape3D = CollisionShape3D.new()
	var wall_shape: BoxShape3D = BoxShape3D.new()
	wall_shape.size = wall_box.size
	wall_collision.shape = wall_shape
	wall_collision.position = wall_mesh.position
	wall.add_child(wall_collision)
	var manager: CameramanClearShot = CameramanClearShot.new()
	manager.name = "ClearShot"
	manager.priority_enabled = true
	manager.priority = 20
	manager.activate_after = 0.2
	manager.min_duration = 1.0
	add_child(manager)
	var offsets: Array[Vector3] = [
		Vector3(-7.0, 3.0, 6.0),
		Vector3(9.0, 3.0, 9.0),
		Vector3(0.0, 5.0, -7.0)
	]
	for index in offsets.size():
		var child: CameramanCamera = _make_camera("ClearShot%d" % index, target)
		child.priority_enabled = true
		child.priority = offsets.size() - index
		var follow: CameramanFollow = child.get_node("Follow") as CameramanFollow
		follow.binding_mode = CameramanFollow.BindingMode.WORLD_SPACE
		follow.follow_offset = offsets[index]
		var deoccluder: CameramanDeoccluder = CameramanDeoccluder.new()
		deoccluder.name = "Deoccluder"
		deoccluder.shot_quality_enabled = true
		child.add_child(deoccluder)
		manager.add_child(child)

func _create_state_driven(target: Node3D) -> void:
	var manager: CameramanStateDrivenCamera = CameramanStateDrivenCamera.new()
	manager.name = "StateDriven"
	manager.priority_enabled = true
	manager.priority = 20
	add_child(manager)
	var idle: CameramanCamera = _make_camera("IdleCamera", target)
	var run: CameramanCamera = _make_camera("RunCamera", target)
	(idle.get_node("Follow") as CameramanFollow).follow_offset = Vector3(-6.0, 3.0, 7.0)
	(run.get_node("Follow") as CameramanFollow).follow_offset = Vector3(6.0, 2.0, 5.0)
	manager.add_child(idle)
	manager.add_child(run)
	_state_player = AnimationPlayer.new()
	_state_player.name = "StateAnimationPlayer"
	var library: AnimationLibrary = AnimationLibrary.new()
	library.add_animation("idle", Animation.new())
	library.add_animation("run", Animation.new())
	_state_player.add_animation_library("", library)
	manager.add_child(_state_player)
	var idle_instruction: CameramanStateDrivenInstruction = CameramanStateDrivenInstruction.new()
	idle_instruction.state_name = &"idle"
	idle_instruction.camera = NodePath("IdleCamera")
	var run_instruction: CameramanStateDrivenInstruction = CameramanStateDrivenInstruction.new()
	run_instruction.state_name = &"run"
	run_instruction.camera = NodePath("RunCamera")
	run_instruction.activate_after = 0.2
	manager.instructions = [idle_instruction, run_instruction]
	manager.animation_player_path = NodePath("StateAnimationPlayer")
	_state_player.play("idle")

func _create_sequence(target: Node3D) -> void:
	var manager: CameramanSequencerCamera = CameramanSequencerCamera.new()
	manager.name = "Sequencer"
	manager.priority_enabled = true
	manager.priority = 20
	add_child(manager)
	var offsets: Array[Vector3] = [
		Vector3(0.0, 4.0, 12.0),
		Vector3(3.0, 2.0, 5.0),
		Vector3(0.0, 9.0, 1.5)
	]
	var instructions: Array[CameramanSequencerInstruction] = []
	for index in offsets.size():
		var camera: CameramanCamera = _make_camera("SequenceCamera%d" % index, target)
		(camera.get_node("Follow") as CameramanFollow).follow_offset = offsets[index]
		manager.add_child(camera)
		var instruction: CameramanSequencerInstruction = CameramanSequencerInstruction.new()
		instruction.camera = NodePath(camera.name)
		instruction.hold = 3.0
		instruction.blend.style = CameramanBlendDefinition.Style.EASE_IN_OUT
		instruction.blend.time = 1.0
		instructions.append(instruction)
	manager.instructions = instructions
	_sequence = manager
	_update_sequence_animation()

func _update_sequence_animation() -> void:
	var sequence: CameramanShotSequence = CameramanShotSequence.new()
	sequence.name = "ShotSequence"
	sequence.brain_path = NodePath("../OutputCamera/Brain")
	add_child(sequence)
	for index in 3:
		var shot: CameramanShot = CameramanShot.new()
		shot.name = "Shot%d" % index
		shot.camera = NodePath("../Sequencer/SequenceCamera%d" % index)
		shot.weight = 1.0 if index == 0 else 0.0
		sequence.add_child(shot)
	var animation_player: AnimationPlayer = AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	var library: AnimationLibrary = AnimationLibrary.new()
	var animation: Animation = Animation.new()
	animation.length = 9.0
	animation.loop_mode = Animation.LOOP_LINEAR
	for index in 3:
		var track: int = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath("ShotSequence/Shot%d:weight" % index))
		var start: float = float(index) * 3.0
		animation.track_insert_key(track, start, 1.0)
		animation.track_insert_key(track, start + 1.0, 0.0)
		animation.track_insert_key(track, start + 2.0, 0.0)
		animation.track_insert_key(track, start + 3.0, 1.0)
	library.add_animation("Shots", animation)
	animation_player.add_animation_library("", library)
	add_child(animation_player)
	animation_player.play("Shots")
	_sequence_player = animation_player

func _create_impulse_setup(camera: CameramanCamera) -> void:
	var noise: CameramanBasicMultiChannelPerlin = CameramanBasicMultiChannelPerlin.new()
	noise.name = "ShakeNoise"
	noise.amplitude_gain = 0.0
	camera.add_child(noise)
	var listener: CameramanImpulseListener = CameramanImpulseListener.new()
	listener.name = "ImpulseListener"
	listener.gain = 1.8
	camera.add_child(listener)
	_impulse_source = CameramanImpulseSource.new()
	_impulse_source.name = "ImpulseSource"
	_impulse_source.position = Vector3(0.0, 1.0, 0.0)
	var definition: CameramanImpulseDefinition = CameramanImpulseDefinition.new()
	definition.impulse_shape = CameramanImpulseDefinition.Shape.EXPLOSION
	definition.impulse_duration = 0.6
	_impulse_source.impulse_definition = definition
	_impulse_source.default_velocity = Vector3(0.0, -0.6, 0.0)
	add_child(_impulse_source)
	var ball: RigidBody3D = RigidBody3D.new()
	ball.name = "ImpulseBall"
	ball.position = Vector3(0.0, 8.0, 0.0)
	var ball_mesh: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.7
	sphere.height = 1.4
	ball_mesh.mesh = sphere
	ball_mesh.material_override = _material(Color("#f4d35e"))
	ball.add_child(ball_mesh)
	var ball_collision: CollisionShape3D = CollisionShape3D.new()
	var ball_shape: SphereShape3D = SphereShape3D.new()
	ball_shape.radius = 0.7
	ball_collision.shape = ball_shape
	ball.add_child(ball_collision)
	add_child(ball)
	var collision_source: CameramanCollisionImpulseSource = CameramanCollisionImpulseSource.new()
	collision_source.name = "CollisionImpulseSource"
	collision_source.default_velocity = Vector3(0.0, -0.6, 0.0)
	collision_source.impulse_definition = definition
	ball.add_child(collision_source)

func _create_split_screen() -> void:
	_create_ground()
	var player_a: CharacterBody3D = _create_player()
	player_a.name = "PlayerA"
	player_a.position = Vector3(-3.0, 1.0, 0.0)
	var player_b: CharacterBody3D = _create_player()
	player_b.name = "PlayerB"
	player_b.position = Vector3(3.0, 1.0, 0.0)
	var world: World3D = get_viewport().world_3d
	var split_layer: CanvasLayer = CanvasLayer.new()
	split_layer.name = "SplitScreenLayer"
	add_child(split_layer)
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.name = "SplitScreen"
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	split_layer.add_child(hbox)
	for index in 2:
		var container: SubViewportContainer = SubViewportContainer.new()
		container.name = "SplitViewportContainer%d" % index
		container.stretch = true
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		hbox.add_child(container)
		var viewport: SubViewport = SubViewport.new()
		viewport.name = "SplitViewport%d" % index
		viewport.handle_input_locally = false
		viewport.own_world_3d = false
		viewport.world_3d = world
		viewport.size = Vector2i(640, 720)
		container.add_child(viewport)
		var output: Camera3D = Camera3D.new()
		output.name = "OutputCamera%d" % index
		viewport.add_child(output)
		_create_brain(output, 1 << index)
		var target: Node3D = player_a if index == 0 else player_b
		var camera: CameramanCamera = _make_camera("SplitCamera%d" % index, target)
		camera.output_channel = 1 << index
		viewport.add_child(camera)

func _create_2d_demo() -> void:
	var background_layer: CanvasLayer = CanvasLayer.new()
	background_layer.name = "BackgroundLayer"
	background_layer.layer = -10
	add_child(background_layer)
	var background: ColorRect = ColorRect.new()
	background.color = Color("#70b7d9")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_layer.add_child(background)
	var level: Node2D = Node2D.new()
	level.name = "Level"
	add_child(level)
	var level_light: DirectionalLight2D = DirectionalLight2D.new()
	level_light.name = "LevelLight"
	level_light.energy = 0.8
	level.add_child(level_light)
	for data in [
		[Vector2(640.0, 620.0), Vector2(1200.0, 80.0), Color("#4d8f58")],
		[Vector2(280.0, 470.0), Vector2(260.0, 35.0), Color("#d99058")],
		[Vector2(700.0, 370.0), Vector2(280.0, 35.0), Color("#9a6bc4")],
		[Vector2(1050.0, 270.0), Vector2(300.0, 35.0), Color("#d36b76")]
	]:
		_add_platform(level, data[0] as Vector2, data[1] as Vector2, data[2] as Color)
	_platformer_player = CameramanDemoPlatformerPlayer.new()
	_platformer_player.name = "PlatformerPlayer"
	_platformer_player.position = Vector2(180.0, 500.0)
	level.add_child(_platformer_player)
	var player_rect: ColorRect = ColorRect.new()
	player_rect.color = Color("#e44747")
	player_rect.size = Vector2(32.0, 48.0)
	player_rect.position = Vector2(-16.0, -24.0)
	_platformer_player.add_child(player_rect)
	var player_collision: CollisionShape2D = CollisionShape2D.new()
	var player_shape: RectangleShape2D = RectangleShape2D.new()
	player_shape.size = Vector2(32.0, 48.0)
	player_collision.shape = player_shape
	_platformer_player.add_child(player_collision)
	_add_platform_boundary(level, Vector2(-20.0, 360.0), Vector2(40.0, 720.0))
	_add_platform_boundary(level, Vector2(1300.0, 360.0), Vector2(40.0, 720.0))
	_add_platform_boundary(level, Vector2(640.0, -20.0), Vector2(1320.0, 40.0))
	var output: Camera2D = Camera2D.new()
	output.name = "OutputCamera"
	add_child(output)
	_brain = CameramanBrain2D.new()
	_brain.name = "Brain2D"
	_brain.update_method = CameramanBrain.UpdateMethod.PROCESS
	_brain.show_debug_text = true
	output.add_child(_brain)
	var camera: CameramanCamera = CameramanCamera.new()
	camera.name = "PlatformerCamera"
	camera.priority_enabled = true
	camera.priority = 10
	camera.lens.mode_override = CameramanLens.Mode.ORTHOGRAPHIC
	camera.lens.orthographic_size = 720.0
	camera.position = Vector3(_platformer_player.position.x, _platformer_player.position.y, 0.0)
	add_child(camera)
	var follow: CameramanFollow = CameramanFollow.new()
	follow.name = "Follow"
	var position_composer: CameramanPositionComposer = CameramanPositionComposer.new()
	position_composer.name = "PositionComposer"
	position_composer.composition.dead_zone_enabled = true
	position_composer.composition.dead_zone_size = Vector2(0.2, 0.2)
	position_composer.damping = Vector3.ONE * 0.2
	camera.add_child(follow)
	camera.add_child(position_composer)
	var confiner: CameramanConfiner2D = CameramanConfiner2D.new()
	confiner.name = "Confiner2D"
	confiner.damping = Vector2.ONE * 0.2
	camera.add_child(confiner)
	_add_2d_bounds(level, confiner)
	_platformer_player.camera_target = camera

func _add_platform(parent: Node2D, center: Vector2, size: Vector2, color: Color) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = center
	parent.add_child(body)
	var visual: Polygon2D = Polygon2D.new()
	var half: Vector2 = size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y)
	])
	visual.color = color
	body.add_child(visual)
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func _add_platform_boundary(parent: Node2D, center: Vector2, size: Vector2) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = center
	parent.add_child(body)
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func _add_2d_bounds(parent: Node2D, confiner: CameramanConfiner2D) -> void:
	var bounds: CollisionPolygon2D = CollisionPolygon2D.new()
	bounds.name = "LevelBounds"
	bounds.polygon = PackedVector2Array([
		Vector2(-500.0, -360.0), Vector2(1780.0, -360.0),
		Vector2(1780.0, 1080.0), Vector2(-500.0, 1080.0)
	])
	parent.add_child(bounds)
	confiner.bounding_shape = NodePath("../Level/LevelBounds")

func _add_hud() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "DemoHUD"
	add_child(layer)
	_label = Label.new()
	_label.anchor_left = 0.0
	_label.anchor_top = 1.0
	_label.anchor_right = 0.0
	_label.anchor_bottom = 1.0
	_label.offset_left = 18.0
	_label.offset_top = -120.0
	_label.offset_right = 720.0
	_label.offset_bottom = -18.0
	_label.add_theme_font_size_override("font_size", 20)
	layer.add_child(_label)
	_update_hud()

func _update_hud() -> void:
	if _label == null:
		return
	var live_name: String = "<none>"
	if _brain != null:
		live_name = _brain.get_live_description()
	var controls: String = "WASD move | Mouse/arrows look | Space jump/impulse | Esc menu"
	var extra: String = ""
	if demo_kind == "sequence" and _sequence_player != null:
		extra = "\nSequence time: %.1fs" % _sequence_player.current_animation_position
	if demo_kind == "state_driven" and _state_player != null:
		extra = "\nState: %s" % _state_player.current_animation
	var live_line: String = "" if demo_kind == "split_screen" else "\nLive camera: %s" % live_name
	_label.text = "%s%s\n%s%s" % [
		demo_kind.replace("_", " ").capitalize(),
		live_line,
		controls,
		extra
	]

func _material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	return material
