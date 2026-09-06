class_name CameramanConfiner3D
## BODY-stage extension that confines the camera to a 3D collision shape.
## Concave shapes must be closed, non-self-intersecting meshes; open meshes have no
## interior and are treated as unconfined.
extends CameramanExtension

@export var bounding_volume: NodePath
@export var damping: Vector3 = Vector3.ZERO
@export var slowing_distance: float = 0.0

var _cached_shape: Shape3D
var _cached_faces: PackedVector3Array = PackedVector3Array()
var _cached_planes: Array[Plane] = []
var _connected_shape: Shape3D
var _hull_epsilon: float = 0.0

func post_pipeline_stage_callback(
	camera: Node,
	stage: CameramanCore.Stage,
	state: CameramanCameraState,
	delta: float
) -> void:
	if stage != CameramanCore.Stage.BODY:
		return
	var shape_node: CollisionShape3D = camera.get_node_or_null(bounding_volume) as CollisionShape3D
	if shape_node == null:
		for child in camera.get_children():
			if child is CollisionShape3D:
				shape_node = child as CollisionShape3D
				break
	var shape: Shape3D = shape_node.shape if shape_node != null else null
	if shape != _connected_shape:
		_disconnect_shape()
		_connected_shape = shape
		if _connected_shape != null and not _connected_shape.changed.is_connected(invalidate_cache):
			_connected_shape.changed.connect(invalidate_cache)
	if shape == null:
		return
	var local: Vector3 = shape_node.global_transform.affine_inverse() * state.raw_position
	var corrected: Vector3 = _closest_point_inside(shape, local)
	var world_corrected: Vector3 = shape_node.global_transform * corrected
	var correction: Vector3 = world_corrected - state.raw_position
	var distance: float = correction.length()
	var weight: Vector3 = Vector3(
		_damping_weight(damping.x, delta, distance),
		_damping_weight(damping.y, delta, distance),
		_damping_weight(damping.z, delta, distance)
	)
	state.position_correction += Vector3(correction.x * weight.x, correction.y * weight.y, correction.z * weight.z)

func invalidate_cache() -> void:
	_cached_shape = null
	_cached_faces = PackedVector3Array()
	_cached_planes = []

func _exit_tree() -> void:
	_disconnect_shape()

func _disconnect_shape() -> void:
	if _connected_shape != null and _connected_shape.changed.is_connected(invalidate_cache):
		_connected_shape.changed.disconnect(invalidate_cache)
	_connected_shape = null

func _damping_weight(damp_time: float, delta: float, distance: float) -> float:
	if distance <= slowing_distance or damp_time <= 0.0:
		return 1.0
	return CameramanDamper.damp(1.0, damp_time, delta)

func _closest_point_inside(shape: Shape3D, point: Vector3) -> Vector3:
	var result: Vector3 = point
	if shape is BoxShape3D:
		var box: BoxShape3D = shape as BoxShape3D
		var half: Vector3 = box.size * 0.5
		result = Vector3(
			clampf(point.x, -half.x, half.x),
			clampf(point.y, -half.y, half.y),
			clampf(point.z, -half.z, half.z)
		)
	elif shape is SphereShape3D:
		var sphere: SphereShape3D = shape as SphereShape3D
		result = point.limit_length(sphere.radius)
	elif shape is CapsuleShape3D:
		var capsule: CapsuleShape3D = shape as CapsuleShape3D
		var half_height: float = maxf(capsule.height * 0.5 - capsule.radius, 0.0)
		var segment_point := Vector3(0.0, clampf(point.y, -half_height, half_height), 0.0)
		result = segment_point + (point - segment_point).limit_length(capsule.radius)
	elif shape is CylinderShape3D:
		var cylinder: CylinderShape3D = shape as CylinderShape3D
		var radial: Vector2 = Vector2(point.x, point.z)
		if radial.length() > cylinder.radius:
			radial = radial.normalized() * cylinder.radius
		result = Vector3(
			radial.x,
			clampf(point.y, -cylinder.height * 0.5, cylinder.height * 0.5),
			radial.y
		)
	elif shape is ConvexPolygonShape3D:
		_ensure_faces(shape)
		if _cached_faces.is_empty():
			return result
		if not _inside_all_planes(point):
			result = _closest_point_on_faces(point)
	elif shape is ConcavePolygonShape3D:
		_ensure_faces(shape)
		if _cached_faces.is_empty():
			return result
		if not _inside_mesh(point):
			result = _closest_point_on_faces(point)
	return result

func _ensure_faces(shape: Shape3D) -> void:
	if _cached_shape == shape and not _cached_faces.is_empty():
		return
	_cached_shape = shape
	_cached_planes = []
	if shape is ConcavePolygonShape3D:
		_cached_faces = (shape as ConcavePolygonShape3D).get_faces()
	else:
		var convex: ConvexPolygonShape3D = shape as ConvexPolygonShape3D
		_cached_faces = PackedVector3Array()
		if convex.points.size() < 4:
			return
		_build_hull(convex.points)

func _build_hull(points: PackedVector3Array) -> void:
	var unique: Array[Vector3] = []
	for point in points:
		var duplicate: bool = false
		for existing in unique:
			if existing.is_equal_approx(point):
				duplicate = true
				break
		if not duplicate:
			unique.append(point)
	if unique.size() < 4:
		return
	var extent_sq: float = 0.0
	for i in range(unique.size()):
		for j in range(i + 1, unique.size()):
			extent_sq = maxf(extent_sq, unique[i].distance_squared_to(unique[j]))
	_hull_epsilon = sqrt(extent_sq) * 1e-5
	var tetrahedron: Array[int] = _find_initial_tetrahedron(unique)
	if tetrahedron.is_empty():
		return
	var interior: Vector3 = Vector3.ZERO
	for index in tetrahedron:
		interior += unique[index]
	interior /= float(tetrahedron.size())
	var faces: Array[Dictionary] = [
		_orient_face(tetrahedron[0], tetrahedron[1], tetrahedron[2], unique, interior),
		_orient_face(tetrahedron[0], tetrahedron[3], tetrahedron[1], unique, interior),
		_orient_face(tetrahedron[0], tetrahedron[2], tetrahedron[3], unique, interior),
		_orient_face(tetrahedron[1], tetrahedron[3], tetrahedron[2], unique, interior),
	]
	var initial_indices: Dictionary = {}
	for index in tetrahedron:
		initial_indices[index] = true
	for point_index in range(unique.size()):
		if initial_indices.has(point_index):
			continue
		var visible: Array[int] = []
		var visible_lookup: Dictionary = {}
		var edges: Dictionary = {}
		for face_index in range(faces.size()):
			var face: Dictionary = faces[face_index]
			var plane: Plane = _face_plane(face, unique)
			if plane.distance_to(unique[point_index]) > _hull_epsilon:
				visible.append(face_index)
				visible_lookup[face_index] = true
				_add_horizon_edge(edges, int(face["a"]), int(face["b"]))
				_add_horizon_edge(edges, int(face["b"]), int(face["c"]))
				_add_horizon_edge(edges, int(face["c"]), int(face["a"]))
		if visible.is_empty():
			continue
		for face_index in range(faces.size() - 1, -1, -1):
			if visible_lookup.has(face_index):
				faces.remove_at(face_index)
		for edge_key in edges:
			var edge: Dictionary = edges[edge_key]
			if int(edge["count"]) == 1:
				faces.append(
					_orient_face(
						int(edge["a"]),
						int(edge["b"]),
						point_index,
						unique,
						interior
					)
				)
	for face in faces:
		_cached_faces.append(unique[int(face["a"])])
		_cached_faces.append(unique[int(face["b"])])
		_cached_faces.append(unique[int(face["c"])])
		_cached_planes.append(_face_plane(face, unique))

func _find_initial_tetrahedron(points: Array[Vector3]) -> Array[int]:
	var first: int = 0
	var second: int = 0
	var longest_distance: float = 0.0
	for i in range(points.size()):
		for j in range(i + 1, points.size()):
			var distance: float = points[i].distance_squared_to(points[j])
			if distance > longest_distance:
				longest_distance = distance
				first = i
				second = j
	var extent_sq: float = longest_distance
	var epsilon_sq: float = maxf(extent_sq * 1e-10, 1e-24)
	if longest_distance <= epsilon_sq:
		return []
	var line: Vector3 = points[second] - points[first]
	var line_length_squared: float = line.length_squared()
	var third: int = -1
	var farthest_line_distance: float = 0.0
	for i in range(points.size()):
		if i == first or i == second:
			continue
		var offset: Vector3 = points[i] - points[first]
		var line_distance: float = line.cross(offset).length_squared() / line_length_squared
		if line_distance > farthest_line_distance:
			farthest_line_distance = line_distance
			third = i
	if third < 0 or farthest_line_distance <= epsilon_sq:
		return []
	var base_plane: Plane = Plane(points[first], points[second], points[third])
	var fourth: int = -1
	var farthest_plane_distance: float = 0.0
	for i in range(points.size()):
		if i == first or i == second or i == third:
			continue
		var plane_distance: float = absf(base_plane.distance_to(points[i]))
		if plane_distance > farthest_plane_distance:
			farthest_plane_distance = plane_distance
			fourth = i
	var epsilon: float = sqrt(extent_sq) * 1e-5
	if fourth < 0 or farthest_plane_distance <= epsilon:
		return []
	return [first, second, third, fourth]

func _orient_face(
	a: int,
	b: int,
	c: int,
	points: Array[Vector3],
	interior: Vector3
) -> Dictionary:
	var face: Dictionary = {"a": a, "b": b, "c": c}
	if _face_plane(face, points).distance_to(interior) > 0.0:
		face = {"a": a, "b": c, "c": b}
	return face

func _face_plane(face: Dictionary, points: Array[Vector3]) -> Plane:
	return Plane(
		points[int(face["a"])],
		points[int(face["b"])],
		points[int(face["c"])]
	)

func _add_horizon_edge(edges: Dictionary, a: int, b: int) -> void:
	var low: int = mini(a, b)
	var high: int = maxi(a, b)
	var key: String = "%d:%d" % [low, high]
	if edges.has(key):
		var edge: Dictionary = edges[key]
		edge["count"] = int(edge["count"]) + 1
		edges[key] = edge
	else:
		edges[key] = {"a": a, "b": b, "count": 1}

func _inside_all_planes(point: Vector3) -> bool:
	for plane in _cached_planes:
		if plane.distance_to(point) > _hull_epsilon:
			return false
	return true

func _inside_mesh(point: Vector3) -> bool:
	var first: bool = _inside_mesh_with_direction(
		point,
		Vector3(1.0, sqrt(2.0), sqrt(3.0)).normalized()
	)
	var second: bool = _inside_mesh_with_direction(
		point,
		Vector3(sqrt(5.0), 1.0, sqrt(7.0)).normalized()
	)
	if first == second:
		return first
	var third: bool = _inside_mesh_with_direction(
		point,
		Vector3(sqrt(11.0), sqrt(13.0), 1.0).normalized()
	)
	return int(first) + int(second) + int(third) >= 2

func _inside_mesh_with_direction(point: Vector3, direction: Vector3) -> bool:
	var hits: int = 0
	for index in range(0, _cached_faces.size() - 2, 3):
		var hit: Variant = Geometry3D.ray_intersects_triangle(
			point,
			direction,
			_cached_faces[index],
			_cached_faces[index + 1],
			_cached_faces[index + 2]
		)
		if hit != null:
			hits += 1
	return hits % 2 == 1

func _closest_point_on_faces(point: Vector3) -> Vector3:
	var best: Vector3 = point
	var best_distance: float = INF
	for index in range(0, _cached_faces.size() - 2, 3):
		var candidate: Vector3 = _closest_point_on_triangle(
			point,
			_cached_faces[index],
			_cached_faces[index + 1],
			_cached_faces[index + 2]
		)
		var distance: float = point.distance_squared_to(candidate)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best

static func _closest_point_on_triangle(point: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var ab: Vector3 = b - a
	var ac: Vector3 = c - a
	var ap: Vector3 = point - a
	var d1: float = ab.dot(ap)
	var d2: float = ac.dot(ap)
	if d1 <= 0.0 and d2 <= 0.0:
		return a
	var bp: Vector3 = point - b
	var d3: float = ab.dot(bp)
	var d4: float = ac.dot(bp)
	if d3 >= 0.0 and d4 <= d3:
		return b
	var vc: float = d1 * d4 - d3 * d2
	if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
		return a + ab * (d1 / maxf(d1 - d3, 0.000001))
	var cp: Vector3 = point - c
	var d5: float = ab.dot(cp)
	var d6: float = ac.dot(cp)
	if d6 >= 0.0 and d5 <= d6:
		return c
	var vb: float = d5 * d2 - d1 * d6
	if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
		return a + ac * (d2 / maxf(d2 - d6, 0.000001))
	var va: float = d3 * d6 - d5 * d4
	if va <= 0.0 and (d4 - d3) >= 0.0 and (d5 - d6) >= 0.0:
		return b + (c - b) * ((d4 - d3) / maxf((d4 - d3) + (d5 - d6), 0.000001))
	var denominator: float = 1.0 / maxf(va + vb + vc, 0.000001)
	return a + ab * (vb * denominator) + ac * (vc * denominator)
