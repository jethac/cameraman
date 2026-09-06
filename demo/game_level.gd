class_name CameramanDemoGameLevel
extends Node3D

const SPAWN_POSITION := Vector3.ZERO
const ARENA_CENTER := Vector3(55.0, 0.0, 30.0)
const COURTYARD_CENTER := Vector3(107.5, 0.0, 30.0)

var _player: CameramanDemoPlayerController
var _output: Camera3D
var _brain: CameramanBrain
var _follow: CameramanCamera
var _aim: CameramanCamera
var _arena: CameramanClearShot
var _dolly: CameramanCamera
var _courtyard: CameramanCamera
var _sign: CameramanCamera
var _courtyard_bounds: CollisionShape3D
var _sign_area: Area3D
var _aim_active: bool = false
var _arena_active: bool = false
var _bridge_active: bool = false
var _courtyard_active: bool = false
var _sign_active: bool = false
var _autopilot: bool = false
var _demo_time: float = 0.0
var _health: float = 100.0
var _shot_count: int = 0
var _fired_autopilot: bool = false
var _hud: Label
var _hit_source: CameramanImpulseSource
var _recoil_source: CameramanImpulseSource
var _hit_definition: CameramanImpulseDefinition
var _enemies: Array[Node3D] = []

func _ready() -> void:
	_autopilot = "--autopilot" in OS.get_cmdline_user_args()
	CameramanDemoHelpers.add_environment(self)
	_create_ground_and_layout()
	_create_player()
	_create_enemies()
	_create_camera_rig()
	_create_triggers()
	_create_hud()

func _process(delta: float) -> void:
	_demo_time += delta
	_update_autopilot()
	_update_camera_priorities()
	_update_player_state(delta)
	_update_courtyard_bounds()
	if Input.is_action_just_pressed("fire"):
		_fire()
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				get_tree().change_scene_to_file("res://demo/main_menu.tscn")

func _create_ground_and_layout() -> void:
	_add_static_box("Ground", Vector3(60.0, -0.25, 15.0), Vector3(140.0, 0.5, 100.0), Color("#26384a"))
	for index in 6:
		var angle: float = TAU * float(index) / 6.0
		var position := Vector3(cos(angle) * 6.0, 0.75, sin(angle) * 6.0)
		_add_static_box(
			"PlazaCrate%d" % index,
			position,
			Vector3.ONE * 1.5,
			Color("#a8744e")
		)
	for index in 4:
		var angle: float = TAU * float(index) / 4.0 + 0.25
		_add_static_box(
			"PlazaPillar%d" % index,
			Vector3(cos(angle) * 9.0, 2.0, sin(angle) * 9.0),
			Vector3(1.0, 4.0, 1.0),
			Color("#527d9c")
		)
	var corridor_color := Color("#59636e")
	_add_static_box("CorridorWallA", Vector3(25.0, 2.0, -1.5), Vector3(30.0, 4.0, 0.5), corridor_color)
	_add_static_box("CorridorWallB", Vector3(25.0, 2.0, 1.5), Vector3(30.0, 4.0, 0.5), corridor_color)
	_add_static_box("CorridorBendA", Vector3(38.5, 2.0, 8.75), Vector3(0.5, 4.0, 14.5), corridor_color)
	_add_static_box("CorridorBendB", Vector3(41.5, 2.0, 8.75), Vector3(0.5, 4.0, 14.5), corridor_color)
	var arena_color := Color("#6b4e72")
	_add_static_box("ArenaBackWall", Vector3(55.0, 2.5, 44.75), Vector3(30.0, 5.0, 0.5), arena_color)
	_add_static_box("ArenaEastWall", Vector3(69.75, 2.5, 30.0), Vector3(0.5, 5.0, 30.0), arena_color)
	_add_static_box("ArenaWestWallA", Vector3(40.25, 2.5, 37.5), Vector3(0.5, 5.0, 15.0), arena_color)
	_add_static_box("ArenaWestWallB", Vector3(40.25, 2.5, 19.0), Vector3(0.5, 5.0, 5.0), arena_color)
	for index in 4:
		var x: float = 47.0 + float(index % 2) * 16.0
		var z: float = 22.0 + float(index / 2) * 16.0
		_add_static_box("ArenaPillar%d" % index, Vector3(x, 2.5, z), Vector3.ONE, Color("#d36b76"), 5.0)
	_add_static_box("BridgeDeck", Vector3(82.5, 3.0, 30.0), Vector3(25.0, 0.6, 2.0), Color("#9e8a55"))
	_add_static_box("BridgeRampStart", Vector3(71.0, 1.5, 30.0), Vector3(3.0, 0.6, 2.0), Color("#9e8a55"), 10.0)
	_add_static_box("BridgeRampEnd", Vector3(95.0, 1.5, 30.0), Vector3(3.0, 0.6, 2.0), Color("#9e8a55"), -10.0)
	var courtyard_color := Color("#3e746b")
	_add_static_box("CourtyardEastWall", Vector3(120.0, 2.0, 30.0), Vector3(0.5, 4.0, 30.0), courtyard_color)
	_add_static_box("CourtyardNorthWall", Vector3(107.5, 2.0, 44.75), Vector3(25.0, 4.0, 0.5), courtyard_color)
	_add_static_box("CourtyardSouthWall", Vector3(107.5, 2.0, 15.25), Vector3(25.0, 4.0, 0.5), courtyard_color)
	for index in 3:
		_add_static_box(
			"CourtyardPillar%d" % index,
			Vector3(101.0 + float(index) * 7.0, 2.0, 30.0),
			Vector3(1.0, 4.0, 1.0),
			Color("#5ca58f")
		)

func _create_player() -> void:
	_player = CameramanDemoHelpers.create_player(self, SPAWN_POSITION + Vector3.UP)
	_player.rotation.y = -PI * 0.5
	_player.speed = 5.0
	_player.mouse_look_enabled = true
	_player.add_to_group("player")
	_recoil_source = _make_impulse_source(
		_player,
		CameramanImpulseDefinition.Shape.RECOIL,
		0.3,
		0.25,
		Vector3(0.0, 0.15, 0.0)
	)
	_hit_definition = CameramanImpulseDefinition.new()
	_hit_definition.impulse_shape = CameramanImpulseDefinition.Shape.BUMP
	_hit_definition.impulse_type = CameramanImpulseDefinition.ImpulseType.DISSIPATING
	_hit_definition.dissipation_distance = 15.0
	_hit_definition.amplitude_gain = 0.6
	_hit_definition.impulse_duration = 0.35
	_hit_source = CameramanImpulseSource.new()
	_hit_source.impulse_definition = _hit_definition
	_player.add_child(_hit_source)

func _create_enemies() -> void:
	var positions: Array[Vector3] = [
		Vector3(50.0, 1.0, 28.0),
		Vector3(58.0, 1.0, 36.0),
		Vector3(64.0, 1.0, 25.0)
	]
	var routes: Array = [
		[Vector3(46.0, 1.0, 22.0), Vector3(54.0, 1.0, 38.0)],
		[Vector3(52.0, 1.0, 40.0), Vector3(64.0, 1.0, 40.0)],
		[Vector3(62.0, 1.0, 22.0), Vector3(66.0, 1.0, 36.0)]
	]
	for index in positions.size():
		var enemy: Node3D = (load("res://demo/game_enemy.gd") as Script).new() as Node3D
		enemy.name = "Enemy%d" % index
		enemy.position = positions[index]
		enemy.set("waypoints", routes[index])
		enemy.set("target", _player)
		add_child(enemy)
		_enemies.append(enemy)

func _create_camera_rig() -> void:
	_output = Camera3D.new()
	_output.name = "OutputCamera"
	add_child(_output)
	_brain = CameramanBrain.new()
	_brain.name = "Brain"
	_brain.update_method = CameramanBrain.UpdateMethod.PROCESS
	_brain.show_debug_text = true
	_brain.show_camera_frustum = false
	_brain.default_blend.style = CameramanBlendDefinition.Style.EASE_IN_OUT
	_brain.default_blend.time = 0.6
	_brain.custom_blends = _make_custom_blends()
	_output.add_child(_brain)
	var cameras: Node3D = Node3D.new()
	cameras.name = "Cameras"
	add_child(cameras)
	_follow = _make_follow_camera(cameras)
	_aim = _make_aim_camera(cameras)
	_arena = _make_arena_camera(cameras)
	_dolly = _make_dolly_camera(cameras)
	_courtyard = _make_courtyard_camera(cameras)
	_sign = _make_sign_camera(cameras)

func _make_follow_camera(parent: Node3D) -> CameramanCamera:
	var camera: CameramanCamera = CameramanCamera.new()
	camera.name = "Follow"
	camera.priority_enabled = true
	camera.priority = 10
	camera.tracking_target = _player
	camera.look_at_target = _player
	parent.add_child(camera)
	var follow: CameramanThirdPersonFollow = CameramanThirdPersonFollow.new()
	follow.shoulder_offset = Vector3(0.6, 1.6, 0.0)
	follow.camera_distance = 4.5
	follow.vertical_arm_length = 0.3
	follow.damping = Vector3.ONE * 0.15
	follow.follow_target = _player
	var avoidance: CameramanObstacleAvoidance = CameramanObstacleAvoidance.new()
	avoidance.enabled = true
	avoidance.camera_radius = 0.3
	avoidance.damping_into = 0.2
	avoidance.damping_from_collision = 0.3
	follow.avoid_obstacles = avoidance
	camera.add_child(follow)
	camera.add_child(_make_deoccluder())
	camera.add_child(_make_listener(1.0))
	return camera

func _make_aim_camera(parent: Node3D) -> CameramanCamera:
	var camera: CameramanCamera = CameramanCamera.new()
	camera.name = "Aim"
	camera.priority_enabled = true
	camera.priority = 0
	camera.tracking_target = _player
	camera.look_at_target = _player
	camera.lens.fov_degrees = 40.0
	parent.add_child(camera)
	var follow: CameramanThirdPersonFollow = CameramanThirdPersonFollow.new()
	follow.shoulder_offset = Vector3(0.9, 1.5, 0.0)
	follow.camera_distance = 1.8
	follow.damping = Vector3.ONE * 0.05
	follow.follow_target = _player
	camera.add_child(follow)
	var aim: CameramanThirdPersonAim = CameramanThirdPersonAim.new()
	aim.aim_collision_mask = 1
	aim.aim_distance = 100.0
	aim.ignore_groups = [&"player"]
	camera.add_child(aim)
	camera.add_child(_make_deoccluder())
	camera.add_child(_make_listener(0.5))
	return camera

func _make_arena_camera(parent: Node3D) -> CameramanClearShot:
	var manager: CameramanClearShot = CameramanClearShot.new()
	manager.name = "ArenaClearShot"
	manager.priority_enabled = true
	manager.priority = 0
	manager.activate_after = 0.5
	manager.min_duration = 2.0
	parent.add_child(manager)
	var corners: Array[Vector3] = [
		Vector3(47.0, 7.0, 22.0),
		Vector3(63.0, 7.0, 22.0),
		Vector3(47.0, 7.0, 40.0),
		Vector3(63.0, 7.0, 40.0)
	]
	for index in corners.size():
		var camera: CameramanCamera = CameramanCamera.new()
		camera.name = "ArenaShot%d" % index
		camera.priority_enabled = true
		camera.priority = 1
		camera.tracking_target = _player
		camera.look_at_target = _player
		camera.position = corners[index]
		manager.add_child(camera)
		var look_at: CameramanHardLookAt = CameramanHardLookAt.new()
		camera.add_child(look_at)
		camera.add_child(_make_deoccluder())
	return manager

func _make_dolly_camera(parent: Node3D) -> CameramanCamera:
	var camera: CameramanCamera = CameramanCamera.new()
	camera.name = "BridgeDolly"
	camera.priority_enabled = true
	camera.priority = 0
	camera.tracking_target = _player
	camera.look_at_target = _player
	parent.add_child(camera)
	var path: Path3D = Path3D.new()
	path.name = "BridgeDollyPath"
	var curve: Curve3D = Curve3D.new()
	curve.add_point(Vector3(70.0, 8.0, 24.0))
	curve.add_point(Vector3(95.0, 8.0, 24.0))
	path.curve = curve
	add_child(path)
	var dolly: CameramanSplineDolly = CameramanSplineDolly.new()
	dolly.spline = path
	dolly.follow_target = _player
	dolly.camera_rotation = CameramanSplineDolly.CameraRotation.FOLLOW_TARGET_NO_ROLL
	dolly.automatic_dolly.enabled = true
	dolly.automatic_dolly.mode = CameramanSplineAutoDolly.Mode.NEAREST_POINT_TO_TARGET
	dolly.automatic_dolly.position_offset = 0.0
	dolly.position_damping = Vector3.ONE * 0.1
	dolly.angular_damping = 0.15
	camera.add_child(dolly)
	var composer: CameramanRotationComposer = CameramanRotationComposer.new()
	composer.composition.dead_zone_enabled = true
	composer.composition.dead_zone_size = Vector2.ONE * 0.1
	composer.damping = Vector2.ONE * 0.15
	camera.add_child(composer)
	return camera

func _make_courtyard_camera(parent: Node3D) -> CameramanCamera:
	var camera: CameramanCamera = CameramanCamera.new()
	camera.name = "Courtyard"
	camera.priority_enabled = true
	camera.priority = 0
	camera.tracking_target = _player
	camera.look_at_target = _player
	parent.add_child(camera)
	var follow: CameramanFollow = CameramanFollow.new()
	follow.follow_target = _player
	follow.follow_offset = Vector3(0.0, 6.0, 9.0)
	follow.binding_mode = CameramanFollow.BindingMode.WORLD_SPACE
	follow.position_damping = Vector3.ONE * 0.3
	camera.add_child(follow)
	var composer: CameramanRotationComposer = CameramanRotationComposer.new()
	composer.composition.dead_zone_enabled = true
	composer.composition.dead_zone_size = Vector2.ONE * 0.1
	composer.damping = Vector2.ONE * 0.2
	camera.add_child(composer)
	_courtyard_bounds = CollisionShape3D.new()
	_courtyard_bounds.name = "CourtyardBounds"
	var prism: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for y in [-3.75, 3.75]:
		for index in 6:
			var angle: float = TAU * float(index) / 6.0
			points.append(Vector3(cos(angle) * 11.0, y, sin(angle) * 11.0))
	prism.points = points
	_courtyard_bounds.shape = prism
	camera.add_child(_courtyard_bounds)
	var confiner: CameramanConfiner3D = CameramanConfiner3D.new()
	confiner.bounding_volume = NodePath("CourtyardBounds")
	confiner.damping = Vector3.ONE * 0.2
	camera.add_child(confiner)
	return camera

func _make_sign_camera(parent: Node3D) -> CameramanCamera:
	var camera: CameramanCamera = CameramanCamera.new()
	camera.name = "Sign"
	camera.priority_enabled = true
	camera.priority = 0
	camera.tracking_target = _player
	camera.look_at_target = _player
	parent.add_child(camera)
	var follow: CameramanFollow = CameramanFollow.new()
	follow.follow_target = _player
	follow.follow_offset = Vector3(0.0, 3.0, 6.0)
	follow.position_damping = Vector3.ONE * 0.15
	camera.add_child(follow)
	var composer: CameramanRotationComposer = CameramanRotationComposer.new()
	composer.damping = Vector2.ONE * 0.15
	camera.add_child(composer)
	var storyboard: CameramanStoryboard = CameramanStoryboard.new()
	storyboard.render_mode = CameramanStoryboard.RenderMode.WORLD_SPACE
	storyboard.image = _make_sign_texture()
	storyboard.alpha = 0.6
	storyboard.world_distance = 2.0
	storyboard.aspect = CameramanStoryboard.Aspect.BEST_FIT
	storyboard.center = Vector2(0.5, 0.25)
	camera.add_child(storyboard)
	return camera

func _create_triggers() -> void:
	_make_trigger("ArenaTrigger", Vector3(55.0, 2.0, 30.0), Vector3(30.0, 4.0, 30.0), _arena)
	_make_trigger("BridgeTrigger", Vector3(82.5, 3.0, 30.0), Vector3(25.0, 6.0, 5.0), _dolly)
	_make_trigger("CourtyardTrigger", COURTYARD_CENTER + Vector3.UP * 2.0, Vector3(25.0, 4.0, 30.0), _courtyard)
	_sign_area = _make_trigger("SignTrigger", Vector3(0.0, 2.0, -12.0), Vector3(8.0, 4.0, 8.0), _sign)

func _make_trigger(
	trigger_name: String,
	position: Vector3,
	size: Vector3,
	camera: CameramanVirtualCameraBase
) -> Area3D:
	var area: Area3D = Area3D.new()
	area.name = trigger_name
	area.position = position
	area.collision_layer = 0
	area.collision_mask = 1
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	area.add_child(collision)
	add_child(area)
	area.body_entered.connect(_on_camera_zone_entered.bind(camera))
	area.body_exited.connect(_on_camera_zone_exited.bind(camera))
	return area

func _on_camera_zone_entered(body: Node3D, camera: CameramanVirtualCameraBase) -> void:
	if body != _player:
		return
	camera.priority = 15
	if camera == _arena:
		_arena_active = true
	elif camera == _dolly:
		_bridge_active = true
	elif camera == _courtyard:
		_courtyard_active = true
	elif camera == _sign:
		_sign_active = true

func _on_camera_zone_exited(body: Node3D, camera: CameramanVirtualCameraBase) -> void:
	if body != _player:
		return
	camera.priority = 0
	if camera == _arena:
		_arena_active = false
	elif camera == _dolly:
		_bridge_active = false
	elif camera == _courtyard:
		_courtyard_active = false
	elif camera == _sign:
		_sign_active = false

func _update_camera_priorities() -> void:
	_aim_active = Input.is_action_pressed("aim")
	_aim.priority = 20 if _aim_active else 0
	_arena.priority = 15 if _arena_active else 0
	_dolly.priority = 30 if _bridge_active else 0
	_courtyard.priority = 15 if _courtyard_active else 0
	_sign.priority = 15 if _sign_active else 0

func _update_player_state(delta: float) -> void:
	_player.speed = 9.0 if Input.is_action_pressed("sprint") else 5.0
	for enemy in _enemies:
		if not is_instance_valid(enemy):
			continue
		if _player.global_position.distance_to(enemy.global_position) < 1.4:
			_health -= 10.0 * delta
			_hit_source.generate_impulse()
	if _health <= 0.0:
		_respawn_player()

func _respawn_player() -> void:
	var delta: Vector3 = SPAWN_POSITION + Vector3.UP - _player.global_position
	_player.global_position = SPAWN_POSITION + Vector3.UP
	_player.velocity = Vector3.ZERO
	_health = 100.0
	if _brain.active_virtual_camera != null:
		_brain.active_virtual_camera.on_target_object_warped(_player, delta)

func _fire() -> void:
	if _output == null:
		return
	var projectile: CameramanDemoProjectile = CameramanDemoProjectile.new()
	projectile.name = "Projectile%d" % _shot_count
	var pivot: Node3D = _player.get_node("PitchPivot") as Node3D
	projectile.global_position = pivot.global_position
	var forward: Vector3 = -_output.global_basis.z
	projectile.linear_velocity = forward * 30.0
	var collision_source: CameramanCollisionImpulseSource = CameramanCollisionImpulseSource.new()
	collision_source.use_impact_direction = true
	collision_source.scale_impact_with_speed = true
	var definition: CameramanImpulseDefinition = CameramanImpulseDefinition.new()
	definition.impulse_shape = CameramanImpulseDefinition.Shape.BUMP
	definition.impulse_type = CameramanImpulseDefinition.ImpulseType.DISSIPATING
	definition.dissipation_distance = 15.0
	definition.amplitude_gain = 0.5
	definition.impulse_duration = 0.4
	collision_source.impulse_definition = definition
	projectile.add_child(collision_source)
	add_child(projectile)
	_recoil_source.generate_impulse_with_velocity(Vector3(0.0, 0.0, -0.35))
	_shot_count += 1

func _update_autopilot() -> void:
	if not _autopilot:
		return
	var autopilot_position: Vector3 = _player.global_position
	_arena_active = _demo_time >= 10.0
	if _demo_time < 4.0:
		autopilot_position = Vector3(_demo_time * 5.0, 0.9, 0.0)
		Input.action_release("aim")
	elif _demo_time < 7.0:
		autopilot_position = Vector3(20.0 + (_demo_time - 4.0) * 6.7, 0.9, 0.0)
		Input.action_release("aim")
	elif _demo_time < 12.0:
		autopilot_position = Vector3(40.0, 0.9, (_demo_time - 7.0) * 4.0)
		Input.action_release("aim")
	elif _demo_time < 14.0:
		autopilot_position = Vector3(40.0, 0.9, 20.0)
		Input.action_press("aim")
		if not _fired_autopilot and _demo_time >= 13.0:
			_fired_autopilot = true
			_fire()
	else:
		autopilot_position = Vector3(40.0, 0.9, 20.0)
		Input.action_release("aim")
	_player.global_position = autopilot_position
	_player.velocity = Vector3.ZERO

func _update_courtyard_bounds() -> void:
	if _courtyard_bounds == null or not _courtyard_bounds.is_inside_tree():
		return
	_courtyard_bounds.global_position = COURTYARD_CENTER + Vector3.UP * 5.25

func _create_hud() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(24.0, 650.0)
	_hud.add_theme_font_size_override("font_size", 18)
	layer.add_child(_hud)

func _update_hud() -> void:
	if _hud == null:
		return
	var remaining: int = 0
	for enemy in _enemies:
		if is_instance_valid(enemy):
			remaining += 1
	_hud.text = (
		"GAME LEVEL\n"
		+ "Health: %.0f   Shots: %d   Enemies: %d\n" % [_health, _shot_count, remaining]
		+ "WASD move   Shift sprint   RMB aim   LMB fire   Space jump"
	)

func _add_static_box(
	box_name: String,
	position: Vector3,
	size: Vector3,
	color: Color,
	height_rotation: float = 0.0
) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = box_name
	body.position = position
	body.rotation.z = deg_to_rad(height_rotation)
	body.collision_layer = 1
	body.collision_mask = 1
	body.add_to_group("level")
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = CameramanDemoHelpers.material(color)
	body.add_child(mesh)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	return body

func _make_deoccluder() -> CameramanDeoccluder:
	var deoccluder: CameramanDeoccluder = CameramanDeoccluder.new()
	deoccluder.collide_against = 1
	deoccluder.camera_radius = 0.3
	deoccluder.strategy = CameramanDeoccluder.Strategy.PULL_CAMERA_FORWARD
	deoccluder.smoothing_time = 0.2
	deoccluder.damping = 0.3
	deoccluder.damping_when_occluded = 0.3
	deoccluder.ignore_group = &"player"
	return deoccluder

func _make_listener(gain: float) -> CameramanImpulseListener:
	var listener: CameramanImpulseListener = CameramanImpulseListener.new()
	listener.gain = gain
	listener.use_2d_distance = false
	return listener

func _make_impulse_source(
	parent: Node3D,
	shape: CameramanImpulseDefinition.Shape,
	amplitude: float,
	duration: float,
	velocity: Vector3
) -> CameramanImpulseSource:
	var source: CameramanImpulseSource = CameramanImpulseSource.new()
	var definition: CameramanImpulseDefinition = CameramanImpulseDefinition.new()
	definition.impulse_shape = shape
	definition.impulse_duration = duration
	definition.amplitude_gain = amplitude
	source.impulse_definition = definition
	source.default_velocity = velocity
	parent.add_child(source)
	return source

func _make_custom_blends() -> CameramanBlenderSettings:
	var settings: CameramanBlenderSettings = CameramanBlenderSettings.new()
	settings.custom_blends = [
		_make_custom_blend("Follow", "Aim", 0.15),
		_make_custom_blend("Aim", "Follow", 0.3),
		_make_custom_blend("**ANY CAMERA**", "BridgeDolly", 1.0),
		_make_custom_blend("**ANY CAMERA**", "Courtyard", 1.0),
		_make_custom_blend("**ANY CAMERA**", "Sign", 1.0)
	]
	return settings

func _make_custom_blend(from_name: String, to_name: String, duration: float) -> CameramanCustomBlend:
	var custom: CameramanCustomBlend = CameramanCustomBlend.new()
	custom.from_name = from_name
	custom.to_name = to_name
	custom.definition = CameramanBlendDefinition.new()
	custom.definition.style = CameramanBlendDefinition.Style.EASE_IN_OUT
	custom.definition.time = duration
	return custom

func _make_sign_texture() -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.colors = PackedColorArray([Color("#17324d"), Color("#42b7c6")])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 512
	texture.height = 256
	return texture
