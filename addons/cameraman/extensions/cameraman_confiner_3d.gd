@tool
class_name CameramanConfiner3D
## Constrains camera state inside a 3D bounding volume during the extension pipeline.
## Key properties include `bounding_volume`, `damping`, `slowing_distance`, which configure its behavior.
extends CameramanExtension

## Configures the bounding volume used by this type.
@export var bounding_volume: NodePath
## Controls the damping applied to damping.
@export var damping: Vector3 = Vector3.ZERO
## Sets the slowing distance used by this type.
@export var slowing_distance: float = 0.0

var _cached_shape: Shape3D
var _cached_faces: PackedVector3Array = PackedVector3Array()
var _cached_planes: Array[Plane] = []

## Applies extension behavior after the specified pipeline stage.
func post_pipeline_stage_callback(
	camera: Node,
	stage: CameramanCore.Stage,
	state: CameramanCameraState,
	delta: float
) -> void:
	if stage != CameramanCore.Stage.BODY:
		return
	if not camera.is_inside_tree():
		return
	var shape_node: CollisionShape3D = camera.get_node_or_null(bounding_volume) as CollisionShape3D
	if shape_node == null:
		for child in camera.get_children():
			if child is CollisionShape3D:
				shape_node = child as CollisionShape3D
				break
	if shape_node == null or not shape_node.is_inside_tree() or shape_node.shape == null:
		return
	var local: Vector3 = shape_node.global_transform.affine_inverse() * state.raw_position
	var corrected: Vector3 = _closest_point_inside(shape_node.shape, local)
	var world_corrected: Vector3 = shape_node.global_transform * corrected
	var correction: Vector3 = world_corrected - state.raw_position
	var distance: float = correction.length()
	var weight: Vector3 = Vector3(
		_damping_weight(damping.x, delta, distance),
		_damping_weight(damping.y, delta, distance),
		_damping_weight(damping.z, delta, distance)
	)
	state.position_correction += Vector3(correction.x * weight.x, correction.y * weight.y, correction.z * weight.z)

## Invalidates cached volume geometry.
func invalidate_cache() -> void:
	_cached_shape = null
	_cached_faces = PackedVector3Array()
	_cached_planes = []

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
		var y: float = clampf(point.y, -half_height, half_height)
		var radial: Vector2 = Vector2(point.x, point.z)
		if radial.length() > capsule.radius:
			radial = radial.normalized() * capsule.radius
		result = Vector3(radial.x, y, radial.y)
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
	var count: int = points.size()
	for i in range(count):
		for j in range(i + 1, count):
			for k in range(j + 1, count):
				var plane: Plane = Plane(points[i], points[j], points[k])
				if plane.normal.is_zero_approx():
					continue
				var positive: bool = false
				var negative: bool = false
				for m in range(count):
					if m == i or m == j or m == k:
						continue
					var side: float = plane.distance_to(points[m])
					if side > 0.0001:
						positive = true
					elif side < -0.0001:
						negative = true
					if positive and negative:
						break
				if positive and negative:
					continue
				if positive:
					plane = Plane(-plane.normal, -plane.d)
				_cached_faces.append(points[i])
				_cached_faces.append(points[j])
				_cached_faces.append(points[k])
				var duplicate: bool = false
				for existing in _cached_planes:
					if existing.normal.is_equal_approx(plane.normal) and is_equal_approx(existing.d, plane.d):
						duplicate = true
						break
				if not duplicate:
					_cached_planes.append(plane)

func _inside_all_planes(point: Vector3) -> bool:
	for plane in _cached_planes:
		if plane.distance_to(point) > 0.0001:
			return false
	return true

func _inside_mesh(point: Vector3) -> bool:
	var direction: Vector3 = Vector3(1.0, 0.1234567, 0.2345678).normalized()
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
