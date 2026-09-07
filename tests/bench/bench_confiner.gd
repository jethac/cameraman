extends SceneTree

## Headless benchmark: 16k-triangle concave sphere closest-point queries.
## Reports microseconds per inside and outside query.
## Run: godot --headless -s tests/bench/bench_confiner.gd

const ITERATIONS: int = 1000

var _confiner: CameramanConfiner3D
var _shape: ConcavePolygonShape3D
var _ran: bool = false


func _initialize() -> void:
	var world: Node3D = Node3D.new()
	root.add_child(world)
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 3.0
	mesh.height = 6.0
	mesh.radial_segments = 128
	mesh.rings = 64
	_shape = ConcavePolygonShape3D.new()
	_shape.set_faces(mesh.get_faces())
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = _shape
	world.add_child(collision)
	_confiner = CameramanConfiner3D.new()
	world.add_child(_confiner)


func _process(_delta: float) -> bool:
	if _ran:
		return true
	_ran = true
	var inside: Vector3 = Vector3.ZERO
	var outside: Vector3 = Vector3(0.0, 0.0, 4.0)
	_confiner._closest_point_inside(_shape, inside)
	_confiner._closest_point_inside(_shape, outside)
	var inside_start: int = Time.get_ticks_usec()
	for _index in ITERATIONS:
		_confiner._closest_point_inside(_shape, inside)
	var inside_elapsed: int = Time.get_ticks_usec() - inside_start
	var outside_start: int = Time.get_ticks_usec()
	for _index in ITERATIONS:
		_confiner._closest_point_inside(_shape, outside)
	var outside_elapsed: int = Time.get_ticks_usec() - outside_start
	print(
		"triangles=%d iterations=%d inside_us_per_call=%.1f outside_us_per_call=%.1f"
		% [
			_shape.get_faces().size() / 3,
			ITERATIONS,
			float(inside_elapsed) / ITERATIONS,
			float(outside_elapsed) / ITERATIONS
		]
	)
	quit()
	return true
