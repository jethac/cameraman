class_name CameramanConfiner2D
extends CameramanExtension

@export var bounding_shape: NodePath
@export var damping: Vector2 = Vector2.ZERO
@export var slowing_distance: float = 0.0
@export var oversize_window: bool = true
@export var max_window_size: Vector2 = Vector2.ZERO

var _cached_polygon: PackedVector2Array = PackedVector2Array()
var _cached_window: Vector2 = Vector2(-1.0, -1.0)
var _cached_oversized: bool = false
var _cache_valid: bool = false

func post_pipeline_stage_callback(
	camera: Node,
	stage: CameramanCore.Stage,
	state: CameramanCameraState,
	delta: float
) -> void:
	if stage != CameramanCore.Stage.BODY:
		return
	var half_window: Vector2 = _get_half_window(state)
	var polygon: PackedVector2Array = _get_shrunk_polygon(camera, half_window)
	if polygon.size() < 3:
		return
	var position: Vector2 = Vector2(state.raw_position.x, state.raw_position.y)
	var desired: Vector2 = _polygon_centroid(polygon) if _cached_oversized else _closest_position(polygon, position)
	var correction: Vector2 = desired - position
	var distance: float = correction.length()
	var weight: Vector2 = Vector2(
		_damping_weight(damping.x, delta, distance),
		_damping_weight(damping.y, delta, distance)
	)
	state.position_correction += Vector3(correction.x * weight.x, correction.y * weight.y, 0.0)

func invalidate_bounding_shape_cache() -> void:
	_cache_valid = false
	_cached_window = Vector2(-1.0, -1.0)
	_cached_oversized = false

func _get_half_window(state: CameramanCameraState) -> Vector2:
	if not state.lens.is_orthographic():
		return Vector2.ZERO
	var half_window: Vector2 = Vector2(
		state.lens.orthographic_size * CameramanCameraState.aspect_ratio * 0.5,
		state.lens.orthographic_size * 0.5
	)
	if max_window_size != Vector2.ZERO:
		half_window = half_window.min(max_window_size * 0.5)
	return half_window if oversize_window else Vector2.ZERO

func _get_shrunk_polygon(camera: Node, half_window: Vector2) -> PackedVector2Array:
	var shape_node: Node = camera.get_node_or_null(bounding_shape)
	var source: PackedVector2Array = _get_source_polygon(shape_node)
	if source.size() < 3:
		return PackedVector2Array()
	if _cache_valid and _cached_window == half_window:
		return _cached_polygon
	var offset: Array[PackedVector2Array] = Geometry2D.offset_polygon(
		source,
		-half_window.x,
		Geometry2D.JOIN_MITER
	)
	if offset.is_empty():
		_cached_polygon = source
		_cached_oversized = true
	else:
		_cached_polygon = _largest_polygon(offset)
		_cached_oversized = _cached_polygon.size() < 3
		if _cached_oversized:
			_cached_polygon = source
	_cached_window = half_window
	_cache_valid = true
	return _cached_polygon

func _get_source_polygon(shape_node: Node) -> PackedVector2Array:
	if shape_node is Polygon2D:
		var polygon_node: Polygon2D = shape_node as Polygon2D
		var result: PackedVector2Array = PackedVector2Array()
		for point in polygon_node.polygon:
			result.append(polygon_node.global_transform * point)
		return result
	if shape_node is CollisionPolygon2D:
		var collision_polygon: CollisionPolygon2D = shape_node as CollisionPolygon2D
		var collision_result: PackedVector2Array = PackedVector2Array()
		for point in collision_polygon.polygon:
			collision_result.append(collision_polygon.global_transform * point)
		return collision_result
	if shape_node is CollisionShape2D:
		var collision_shape: CollisionShape2D = shape_node as CollisionShape2D
		if collision_shape.shape is RectangleShape2D:
			var rectangle: RectangleShape2D = collision_shape.shape as RectangleShape2D
			var half: Vector2 = rectangle.size * 0.5
			var corners: PackedVector2Array = PackedVector2Array([
				Vector2(-half.x, -half.y),
				Vector2(half.x, -half.y),
				Vector2(half.x, half.y),
				Vector2(-half.x, half.y)
			])
			var transformed: PackedVector2Array = PackedVector2Array()
			for point in corners:
				transformed.append(collision_shape.global_transform * point)
			return transformed
	return PackedVector2Array()

func _largest_polygon(polygons: Array[PackedVector2Array]) -> PackedVector2Array:
	var largest: PackedVector2Array = PackedVector2Array()
	var largest_area: float = -1.0
	for polygon in polygons:
		var area: float = 0.0
		for index in polygon.size():
			var next: int = (index + 1) % polygon.size()
			area += polygon[index].cross(polygon[next])
		area = absf(area) * 0.5
		if area > largest_area:
			largest_area = area
			largest = polygon
	return largest

func _closest_position(polygon: PackedVector2Array, position: Vector2) -> Vector2:
	if Geometry2D.is_point_in_polygon(position, polygon):
		return position
	var closest: Vector2 = polygon[0]
	var closest_distance: float = INF
	for index in polygon.size():
		var candidate: Vector2 = Geometry2D.get_closest_point_to_segment(
			position,
			polygon[index],
			polygon[(index + 1) % polygon.size()]
		)
		var distance: float = position.distance_squared_to(candidate)
		if distance < closest_distance:
			closest_distance = distance
			closest = candidate
	return closest

func _polygon_centroid(polygon: PackedVector2Array) -> Vector2:
	var centroid: Vector2 = Vector2.ZERO
	for point in polygon:
		centroid += point
	return centroid / maxf(float(polygon.size()), 1.0)

func _damping_weight(damp_time: float, delta: float, distance: float) -> float:
	if distance <= slowing_distance or damp_time <= 0.0:
		return 1.0
	return CameramanDamper.damp(1.0, damp_time, delta)
