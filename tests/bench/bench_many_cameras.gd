extends SceneTree

## Headless benchmark: N standby virtual cameras + one live camera with damping/noise,
## driven by a brain in MANUAL update mode. Reports microseconds per brain update.
## Run: godot --headless -s tests/bench/bench_many_cameras.gd -- 200

const FRAMES: int = 600

var _world: Node3D
var _target: Node3D
var _brain: CameramanBrain
var _count: int = 0
var _ran: bool = false


func _initialize() -> void:
	var count: int = 200
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty():
		count = int(args[0])
	var world: Node3D = Node3D.new()
	root.add_child(world)
	var target: Node3D = Node3D.new()
	world.add_child(target)
	var output: Camera3D = Camera3D.new()
	world.add_child(output)
	var brain: CameramanBrain = CameramanBrain.new()
	brain.update_method = CameramanBrain.UpdateMethod.MANUAL
	output.add_child(brain)
	for index in count:
		var camera: CameramanCamera = CameramanCamera.new()
		camera.name = "Cam%d" % index
		camera.priority_enabled = true
		camera.priority = 1 + (index % 5)
		camera.position = Vector3(index * 0.5, 2.0, 5.0)
		var follow: CameramanFollow = CameramanFollow.new()
		follow.follow_offset = Vector3(0.0, 2.0, 5.0)
		follow.position_damping = Vector3.ONE * 0.5
		camera.add_child(follow)
		var composer: CameramanRotationComposer = CameramanRotationComposer.new()
		composer.damping = Vector2.ONE * 0.3
		camera.add_child(composer)
		var noise: CameramanBasicMultiChannelPerlin = CameramanBasicMultiChannelPerlin.new()
		camera.add_child(noise)
		camera.tracking_target = target

		world.add_child(camera)
	_world = world
	_target = target
	_brain = brain
	_count = count


func _process(_delta: float) -> bool:
	if _ran:
		return true
	_ran = true
	var world: Node3D = _world
	var target: Node3D = _target
	var brain: CameramanBrain = _brain
	var count: int = _count
	brain.manual_update(1.0 / 60.0)
	assert(brain.active_virtual_camera != null)
	var start: int = Time.get_ticks_usec()
	for frame in FRAMES:
		target.position = Vector3(sin(frame * 0.05) * 3.0, 1.0, cos(frame * 0.05) * 3.0)
		if frame % 120 == 0:
			var camera: CameramanCamera = (
				world.get_node("Cam%d" % ((frame / 120) % count)) as CameramanCamera
			)
			camera.priority = 100 + frame
		brain.manual_update(1.0 / 60.0)
	var elapsed: int = Time.get_ticks_usec() - start
	print(
		(
			"cameras=%d frames=%d total_ms=%.1f per_frame_us=%.1f"
			% [count, FRAMES, elapsed / 1000.0, float(elapsed) / FRAMES]
		)
	)
	quit()
	return true
