@tool
class_name CameramanConfiner3D
## FINALIZE-stage extension that constrains camera position inside a 3D volume.
## Concave shapes must be closed, non-self-intersecting meshes; open meshes are
## detected, warned about, and treated as unconfined.
extends CameramanExtension

## NodePath to the 3D collision volume containing the camera.
@export var bounding_volume: NodePath
## Per-axis seconds used when approaching a volume boundary.
@export var damping: Vector3 = Vector3.ZERO
## Distance in meters from a boundary where damping begins to increase.
@export var slowing_distance: float = 0.0

var _cached_shape: Shape3D
var _cached_faces: PackedVector3Array = PackedVector3Array()
var _cached_planes: Array[Plane] = []
var _connected_shape: Shape3D
var _hull_epsilon: float = 0.0
var _bvh_bounds: Array[AABB] = []
var _bvh_left: PackedInt32Array = PackedInt32Array()
var _bvh_right: PackedInt32Array = PackedInt32Array()
var _bvh_start: PackedInt32Array = PackedInt32Array()
var _bvh_count: PackedInt32Array = PackedInt32Array()
var _bvh_tris: PackedInt32Array = PackedInt32Array()
var _bvh_sort_axis: int = 0
var _cached_invalid: bool = false
var _warned_shape: Shape3D

func post_pipeline_stage_callback(
	camera: Node,
	stage: CameramanCore.Stage,
	state: CameramanCameraState,
	delta: float
) -> void:
	if stage != CameramanCore.Stage.BODY:
		return
	if not camera.is_inside_tree():
		_disconnect_shape()
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
	if shape_node == null or not shape_node.is_inside_tree() or shape == null:
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

## Clears cached volume geometry after the bounding node changes.
func invalidate_cache() -> void:
	_cached_shape = null
	_cached_faces = PackedVector3Array()
	_cached_planes = []
	_bvh_bounds = []
	_bvh_left = PackedInt32Array()
	_bvh_right = PackedInt32Array()
	_bvh_start = PackedInt32Array()
	_bvh_count = PackedInt32Array()
	_bvh_tris = PackedInt32Array()
	_hull_epsilon = 0.0
	_cached_invalid = false
	_warned_shape = null

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
	if _cached_shape == shape and (_cached_invalid or not _cached_faces.is_empty()):
		return
	if _cached_shape != shape:
		_cached_invalid = false
		_warned_shape = null
	_cached_shape = shape
	_cached_faces = PackedVector3Array()
	_cached_planes = []
	_hull_epsilon = 0.0
	if shape is ConcavePolygonShape3D:
		_cached_faces = (shape as ConcavePolygonShape3D).get_faces()
		if not _is_closed_mesh(_cached_faces):
			_cached_faces = PackedVector3Array()
			_cached_invalid = true
			if _warned_shape != shape:
				var owner_path: String = (
					str(get_path()) if is_inside_tree() else "<unparented>"
				)
				var warning: String = (
					"%s: concave confiner mesh is not closed " % owner_path
				)
				warning += "(every edge must be shared by exactly two triangles); "
				warning += "confinement disabled."
				push_warning(warning)
				_warned_shape = shape
			return
	else:
		var convex: ConvexPolygonShape3D = shape as ConvexPolygonShape3D
		if convex.points.size() < 4:
			return
		_build_hull(convex.points)
		if _cached_faces.is_empty():
			_cached_invalid = true
			if _warned_shape != shape:
				var owner_path: String = (
					str(get_path()) if is_inside_tree() else "<unparented>"
				)
				push_warning(
					"%s: convex confiner points are coplanar or thinner than 1e-5 "
					% owner_path
					+ "of their extent; confinement disabled."
				)
				_warned_shape = shape
			return
	if not _cached_faces.is_empty():
		_build_bvh()

static func _is_closed_mesh(faces: PackedVector3Array) -> bool:
	if faces.is_empty() or faces.size() % 3 != 0:
		return false
	var edges: Dictionary = {}
	for index in range(0, faces.size(), 3):
		var a: Vector3 = faces[index]
		var b: Vector3 = faces[index + 1]
		var c: Vector3 = faces[index + 2]
		if (b - a).cross(c - a).length_squared() == 0.0:
			continue
		for edge in [
			_mesh_edge_key(a, b),
			_mesh_edge_key(b, c),
			_mesh_edge_key(c, a)
		]:
			edges[edge] = int(edges.get(edge, 0)) + 1
	if edges.is_empty():
		return false
	for count in edges.values():
		if count != 2:
			return false
	return true

static func _mesh_edge_key(a: Vector3, b: Vector3) -> String:
	var first: Vector3 = _canonical_mesh_vertex(a)
	var second: Vector3 = _canonical_mesh_vertex(b)
	if _vector_less(second, first):
		var swap: Vector3 = first
		first = second
		second = swap
	return "%s|%s" % [first, second]

static func _canonical_mesh_vertex(point: Vector3) -> Vector3:
	var snapped: Vector3 = point.snapped(Vector3.ONE * 1e-6)
	return Vector3(
		0.0 if is_zero_approx(snapped.x) else snapped.x,
		0.0 if is_zero_approx(snapped.y) else snapped.y,
		0.0 if is_zero_approx(snapped.z) else snapped.z
	)

static func _vector_less(a: Vector3, b: Vector3) -> bool:
	if a.x != b.x:
		return a.x < b.x
	if a.y != b.y:
		return a.y < b.y
	return a.z < b.z

func _build_hull(points: PackedVector3Array) -> void:
	var unique: Array[Vector3] = []
	var unique_lookup: Dictionary = {}
	for point in points:
		var key: Vector3 = point.snapped(Vector3.ONE * 1e-6)
		if not unique_lookup.has(key):
			unique_lookup[key] = true
			unique.append(point)
	if unique.size() < 4:
		return
	var bounds: AABB = AABB(unique[0], Vector3.ZERO)
	for point in unique:
		bounds = bounds.expand(point)
	var extent_sq: float = bounds.size.length_squared()
	_hull_epsilon = sqrt(extent_sq) * 1e-5
	var tetrahedron: Array[int] = _find_initial_tetrahedron(unique, extent_sq, bounds)
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

func _find_initial_tetrahedron(
	points: Array[Vector3],
	extent_sq: float,
	bounds: AABB
) -> Array[int]:
	var axis: int = 0
	if bounds.size.y > bounds.size.x and bounds.size.y >= bounds.size.z:
		axis = 1
	elif bounds.size.z > bounds.size.x:
		axis = 2
	var first: int = 0
	var second: int = 0
	for index in range(1, points.size()):
		if points[index][axis] < points[first][axis]:
			first = index
		if points[index][axis] > points[second][axis]:
			second = index
	var longest_distance: float = points[first].distance_squared_to(points[second])
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

func _build_bvh() -> void:
	_bvh_bounds = []
	_bvh_left = PackedInt32Array()
	_bvh_right = PackedInt32Array()
	_bvh_start = PackedInt32Array()
	_bvh_count = PackedInt32Array()
	_bvh_tris = PackedInt32Array()
	var triangle_count: int = _cached_faces.size() / 3
	for index in range(triangle_count):
		_bvh_tris.append(index)
	if triangle_count > 0:
		_build_bvh_node(0, triangle_count)

func _build_bvh_node(start: int, end: int) -> int:
	var bounds: AABB = _triangle_aabb(_bvh_tris[start])
	var centroid_bounds: AABB = AABB(_triangle_centroid(_bvh_tris[start]), Vector3.ZERO)
	for index in range(start + 1, end):
		var triangle: int = _bvh_tris[index]
		bounds = bounds.merge(_triangle_aabb(triangle))
		centroid_bounds = centroid_bounds.expand(_triangle_centroid(triangle))
	bounds = bounds.grow(maxf(_hull_epsilon, 1e-6))
	var node: int = _bvh_bounds.size()
	_bvh_bounds.append(bounds)
	_bvh_left.append(-1)
	_bvh_right.append(-1)
	_bvh_start.append(0)
	_bvh_count.append(0)
	var count: int = end - start
	if count <= 4 or centroid_bounds.size.length_squared() <= 1e-20:
		_bvh_start[node] = start
		_bvh_count[node] = count
		return node
	var axis: int = 0
	if centroid_bounds.size.y > centroid_bounds.size.x:
		axis = 1
	if centroid_bounds.size.z > centroid_bounds.size[axis]:
		axis = 2
	var sorted: Array[int] = []
	for index in range(start, end):
		sorted.append(_bvh_tris[index])
	_bvh_sort_axis = axis
	sorted.sort_custom(Callable(self, "_sort_bvh_triangles"))
	for index in range(sorted.size()):
		_bvh_tris[start + index] = sorted[index]
	var middle: int = start + count / 2
	var left: int = _build_bvh_node(start, middle)
	var right: int = _build_bvh_node(middle, end)
	_bvh_left[node] = left
	_bvh_right[node] = right
	return node

func _sort_bvh_triangles(first: int, second: int) -> bool:
	return _triangle_centroid(first)[_bvh_sort_axis] < _triangle_centroid(second)[_bvh_sort_axis]

func _triangle_aabb(triangle: int) -> AABB:
	var index: int = triangle * 3
	return AABB(_cached_faces[index], Vector3.ZERO).expand(
		_cached_faces[index + 1]
	).expand(_cached_faces[index + 2])

func _triangle_centroid(triangle: int) -> Vector3:
	var index: int = triangle * 3
	return (
		_cached_faces[index]
		+ _cached_faces[index + 1]
		+ _cached_faces[index + 2]
	) / 3.0

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
	var stack: Array[int] = [0]
	while not stack.is_empty():
		var node: int = stack.pop_back()
		if _bvh_bounds[node].intersects_ray(point, direction) == null:
			continue
		var count: int = _bvh_count[node]
		if count > 0:
			var start: int = _bvh_start[node]
			for offset in range(count):
				var index: int = _bvh_tris[start + offset] * 3
				var hit: Variant = Geometry3D.ray_intersects_triangle(
					point,
					direction,
					_cached_faces[index],
					_cached_faces[index + 1],
					_cached_faces[index + 2]
				)
				if hit != null:
					hits += 1
		else:
			stack.append(_bvh_left[node])
			stack.append(_bvh_right[node])
	return hits % 2 == 1

func _closest_point_on_faces(point: Vector3) -> Vector3:
	var best: Vector3 = point
	var best_distance: float = INF
	var stack: Array[int] = [0]
	while not stack.is_empty():
		var node: int = stack.pop_back()
		var node_distance: float = _aabb_distance_squared(point, _bvh_bounds[node])
		if node_distance >= best_distance:
			continue
		var count: int = _bvh_count[node]
		if count > 0:
			var start: int = _bvh_start[node]
			for offset in range(count):
				var index: int = _bvh_tris[start + offset] * 3
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
		else:
			var left: int = _bvh_left[node]
			var right: int = _bvh_right[node]
			var left_distance: float = _aabb_distance_squared(point, _bvh_bounds[left])
			var right_distance: float = _aabb_distance_squared(point, _bvh_bounds[right])
			if left_distance < right_distance:
				stack.append(right)
				stack.append(left)
			else:
				stack.append(left)
				stack.append(right)
	return best

func _aabb_distance_squared(point: Vector3, bounds: AABB) -> float:
	var closest: Vector3 = point.clamp(bounds.position, bounds.end)
	return point.distance_squared_to(closest)

static func _closest_point_on_triangle(point: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var ab: Vector3 = b - a
	var ac: Vector3 = c - a
	var normal: Vector3 = ab.cross(ac)
	if normal.length_squared() == 0.0:
		var bc: Vector3 = c - b
		var ab_length: float = ab.length_squared()
		var ac_length: float = ac.length_squared()
		var bc_length: float = bc.length_squared()
		if ab_length >= ac_length and ab_length >= bc_length:
			return Geometry3D.get_closest_point_to_segment(point, a, b)
		if ac_length >= bc_length:
			return Geometry3D.get_closest_point_to_segment(point, a, c)
		return Geometry3D.get_closest_point_to_segment(point, b, c)
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
		return a + ab * (d1 / (d1 - d3))
	var cp: Vector3 = point - c
	var d5: float = ab.dot(cp)
	var d6: float = ac.dot(cp)
	if d6 >= 0.0 and d5 <= d6:
		return c
	var vb: float = d5 * d2 - d1 * d6
	if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
		return a + ac * (d2 / (d2 - d6))
	var va: float = d3 * d6 - d5 * d4
	if va <= 0.0 and (d4 - d3) >= 0.0 and (d5 - d6) >= 0.0:
		return b + (c - b) * ((d4 - d3) / ((d4 - d3) + (d5 - d6)))
	var denominator: float = 1.0 / (va + vb + vc)
	return a + ab * (vb * denominator) + ac * (vc * denominator)
