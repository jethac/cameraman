extends GutTest

func test_confiner_3d_open_concave_mesh_is_unconfined() -> void:
	var camera: Node3D = Node3D.new()
	add_child_autofree(camera)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var concave: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	concave.set_faces(PackedVector3Array([
		Vector3(-1.0, 0.0, -1.0), Vector3(1.0, 0.0, -1.0), Vector3(1.0, 0.0, 1.0),
		Vector3(-1.0, 0.0, -1.0), Vector3(1.0, 0.0, 1.0), Vector3(-1.0, 0.0, 1.0)
	]))
	shape.shape = concave
	camera.add_child(shape)
	var extension: CameramanConfiner3D = CameramanConfiner3D.new()
	autofree(extension)
	var state: CameramanCameraState = CameramanCameraState.create_default()
	state.raw_position = Vector3(0.0, 2.0, 0.0)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, state, 0.1)
	assert_almost_eq(state.get_final_position(), state.raw_position, Vector3.ONE * 0.001)

func test_confiner_3d_concave_sphere_uses_bvh_for_clamping() -> void:
	var camera: Node3D = Node3D.new()
	add_child_autofree(camera)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 32
	mesh.rings = 16
	var concave: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	concave.set_faces(mesh.get_faces())
	shape.shape = concave
	camera.add_child(shape)
	var extension: CameramanConfiner3D = CameramanConfiner3D.new()
	autofree(extension)
	var inside: CameramanCameraState = CameramanCameraState.create_default()
	inside.raw_position = Vector3.ZERO
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, inside, 0.1)
	assert_almost_eq(inside.get_final_position(), Vector3.ZERO, Vector3.ONE * 0.001)
	var outside: CameramanCameraState = CameramanCameraState.create_default()
	outside.raw_position = Vector3(0.0, 0.0, 3.0)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, outside, 0.1)
	assert_almost_eq(outside.get_final_position().length(), 1.0, 0.01)
	assert_almost_eq(
		outside.get_final_position().normalized(),
		Vector3(0.0, 0.0, 1.0),
		Vector3.ONE * 0.01
	)

func test_confiner_3d_convex_hull_handles_random_unit_sphere_points() -> void:
	var camera: Node3D = Node3D.new()
	add_child_autofree(camera)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var convex: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	var random := RandomNumberGenerator.new()
	random.seed = 1907
	var points: PackedVector3Array = PackedVector3Array()
	for _index in range(200):
		var direction := Vector3(
			random.randf_range(-1.0, 1.0),
			random.randf_range(-1.0, 1.0),
			random.randf_range(-1.0, 1.0)
		)
		if direction.length_squared() == 0.0:
			direction = Vector3.RIGHT
		points.append(direction.normalized())
	convex.points = points
	shape.shape = convex
	camera.add_child(shape)
	var extension: CameramanConfiner3D = CameramanConfiner3D.new()
	autofree(extension)
	var outside: CameramanCameraState = CameramanCameraState.create_default()
	outside.raw_position = Vector3(2.0, 0.0, 0.0)
	extension.post_pipeline_stage_callback(camera, CameramanCore.Stage.BODY, outside, 0.1)
	assert_false(extension._cached_faces.is_empty())
	assert_almost_eq(outside.get_final_position().length(), 1.0, 0.1)
