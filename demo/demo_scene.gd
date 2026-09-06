class_name CameramanDemoScene
extends Node

@export var demo_kind: String = "third_person"
@export var is_2d: bool = false

func _ready() -> void:
	if is_2d:
		_create_2d_demo()
	else:
		_create_3d_demo()

func _unhandled_input(event: InputEvent) -> void:
	if demo_kind == "impulse" and event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		var source: CameramanImpulseSource = get_node_or_null("ImpulseSource") as CameramanImpulseSource
		if source != null:
			source.generate_impulse()

func _create_3d_demo() -> void:
	if demo_kind == "split_screen":
		_create_split_screen()
		return
	var player: CharacterBody3D = _create_player()
	_create_ground()
	var output: Camera3D = Camera3D.new()
	output.name = "OutputCamera"
	add_child(output)
	var brain: CameramanBrain = CameramanBrain.new()
	brain.name = "Brain"
	brain.update_method = CameramanBrain.UpdateMethod.PROCESS
	output.add_child(brain)
	var camera: CameramanVirtualCameraBase
	if demo_kind == "clear_shot":
		var manager: CameramanClearShot = CameramanClearShot.new()
		manager.name = "ClearShot"
		add_child(manager)
		camera = _make_camera("ClearShotChild", player)
		manager.add_child(camera)
		var second: CameramanCamera = _make_camera("ClearShotChildB", player)
		second.priority_enabled = true
		second.priority = 1
		manager.add_child(second)
	elif demo_kind == "state_driven":
		var manager_state: CameramanStateDrivenCamera = CameramanStateDrivenCamera.new()
		manager_state.name = "StateDriven"
		add_child(manager_state)
		camera = _make_camera("StateDrivenChild", player)
		manager_state.add_child(camera)
	elif demo_kind == "sequencer":
		var manager_sequence: CameramanSequencerCamera = CameramanSequencerCamera.new()
		manager_sequence.name = "Sequencer"
		add_child(manager_sequence)
		camera = _make_camera("SequencerChild", player)
		manager_sequence.add_child(camera)
	else:
		camera = _make_camera(demo_kind.capitalize(), player)
		add_child(camera)
	camera.priority_enabled = true
	camera.priority = 1
	if demo_kind == "dolly":
		var path: Path3D = Path3D.new()
		path.name = "DollyPath"
		var curve: Curve3D = Curve3D.new()
		curve.add_point(Vector3(-8.0, 2.0, 4.0))
		curve.add_point(Vector3(0.0, 3.0, 0.0))
		curve.add_point(Vector3(8.0, 2.0, -4.0))
		path.curve = curve
		add_child(path)
		var dolly: CameramanSplineDolly = camera.get_node_or_null("SplineDolly") as CameramanSplineDolly
		if dolly != null:
			dolly.spline = path
	if demo_kind == "impulse":
		var source: CameramanImpulseSource = CameramanImpulseSource.new()
		source.name = "ImpulseSource"
		add_child(source)
	if demo_kind == "sequence":
		var sequence: CameramanShotSequence = CameramanShotSequence.new()
		sequence.name = "ShotSequence"
		sequence.brain_path = NodePath("../OutputCamera/Brain")
		add_child(sequence)
		var shot: CameramanShot = CameramanShot.new()
		shot.name = "Shot"
		shot.camera = NodePath("../%s" % camera.name)
		shot.active = true
		shot.weight = 1.0
		sequence.add_child(shot)
		var animation_player: AnimationPlayer = AnimationPlayer.new()
		animation_player.name = "AnimationPlayer"
		var library: AnimationLibrary = AnimationLibrary.new()
		var animation: Animation = Animation.new()
		var track: int = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath("ShotSequence/Shot:weight"))
		animation.track_insert_key(track, 0.0, 1.0)
		animation.track_insert_key(track, 2.0, 0.0)
		library.add_animation("ShotSequence", animation)
		animation_player.add_animation_library("", library)
		add_child(animation_player)
		animation_player.play("ShotSequence")

func _create_split_screen() -> void:
	for index in range(2):
		var container: SubViewportContainer = SubViewportContainer.new()
		container.name = "SplitViewportContainer%d" % index
		container.size = Vector2i(640, 360)
		container.position = Vector2(640 * index, 0.0)
		add_child(container)
		var viewport: SubViewport = SubViewport.new()
		viewport.name = "SplitViewport%d" % index
		viewport.size = Vector2i(640, 360)
		container.add_child(viewport)
		var output: Camera3D = Camera3D.new()
		output.name = "OutputCamera%d" % index
		viewport.add_child(output)
		var brain: CameramanBrain = CameramanBrain.new()
		brain.name = "Brain%d" % index
		brain.channel_mask = 1 << index
		brain.update_method = CameramanBrain.UpdateMethod.PROCESS
		output.add_child(brain)
		var camera: CameramanCamera = _make_camera("SplitCamera%d" % index)
		camera.output_channel = 1 << index
		add_child(camera)

func _create_2d_demo() -> void:
	var player: CameramanDemoPlatformerPlayer = CameramanDemoPlatformerPlayer.new()
	player.name = "PlatformerPlayer"
	add_child(player)
	var output: Camera2D = Camera2D.new()
	output.name = "OutputCamera"
	add_child(output)
	var brain: CameramanBrain2D = CameramanBrain2D.new()
	brain.name = "Brain2D"
	brain.update_method = CameramanBrain.UpdateMethod.PROCESS
	output.add_child(brain)
	var camera: CameramanCamera = _make_camera("PlatformerCamera")
	camera.lens.mode_override = CameramanLens.Mode.ORTHOGRAPHIC
	add_child(camera)

func _make_camera(camera_name: String, target: Node3D = null) -> CameramanCamera:
	var camera: CameramanCamera = CameramanCamera.new()
	camera.name = camera_name
	camera.priority_enabled = true
	camera.tracking_target = target
	if demo_kind == "free_look":
		var orbital: CameramanOrbitalFollow = CameramanOrbitalFollow.new()
		orbital.name = "OrbitalFollow"
		orbital.follow_target = target
		camera.add_child(orbital)
		var input_controller: CameramanInputAxisController = CameramanInputAxisController.new()
		input_controller.name = "InputAxisController"
		camera.add_child(input_controller)
	elif demo_kind == "third_person":
		var third_person: CameramanThirdPersonFollow = CameramanThirdPersonFollow.new()
		third_person.name = "ThirdPersonFollow"
		third_person.follow_target = target
		camera.add_child(third_person)
	elif demo_kind == "dolly":
		var dolly: CameramanSplineDolly = CameramanSplineDolly.new()
		dolly.name = "SplineDolly"
		dolly.follow_target = target
		camera.add_child(dolly)
	else:
		var follow: CameramanFollow = CameramanFollow.new()
		follow.name = "Follow"
		follow.follow_target = target
		follow.follow_offset = Vector3(0.0, 2.0, 6.0)
		camera.add_child(follow)
	var composer: CameramanRotationComposer = CameramanRotationComposer.new()
	composer.name = "RotationComposer"
	camera.add_child(composer)
	return camera

func _create_player() -> CharacterBody3D:
	var player: CameramanDemoPlayerController = CameramanDemoPlayerController.new()
	player.name = "Player"
	player.position = Vector3(0.0, 0.5, 0.0)
	add_child(player)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	mesh.mesh = sphere
	player.add_child(mesh)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: SphereShape3D = SphereShape3D.new()
	shape.radius = 0.5
	collision.shape = shape
	player.add_child(collision)
	return player

func _create_ground() -> void:
	var ground: StaticBody3D = StaticBody3D.new()
	ground.name = "Ground"
	add_child(ground)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(30.0, 0.2, 30.0)
	mesh.mesh = box
	mesh.position.y = -0.6
	ground.add_child(mesh)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = box.size
	collision.shape = shape
	collision.position.y = -0.6
	ground.add_child(collision)
