class_name CameramanConfiner2D
extends CameramanExtension

@export var bounding_shape: NodePath
@export var damping: Vector2 = Vector2.ZERO
@export var slowing_distance: float = 0.0
@export var oversize_window: bool = true
@export var max_window_size: Vector2 = Vector2.ZERO

var _cached_bounds: Rect2
var _cache_valid: bool = false

func post_pipeline_stage_callback(
	camera: Node,
	stage: CameramanCore.Stage,
	state: CameramanCameraState,
	delta: float
) -> void:
	if stage != CameramanCore.Stage.BODY:
		return
	var bounds: Rect2 = _get_bounds(camera)
	if not _cache_valid:
		return
	var half_window: Vector2 = Vector2.ZERO
	if oversize_window:
		half_window = Vector2(CameramanCameraState.aspect_ratio, 1.0) * state.lens.orthographic_size * 0.5
	if max_window_size != Vector2.ZERO:
		half_window = half_window.min(max_window_size * 0.5)
	var min_position: Vector2 = bounds.position + half_window
	var max_position: Vector2 = bounds.end - half_window
	var desired: Vector2 = Vector2(state.raw_position.x, state.raw_position.y)
	if min_position.x > max_position.x:
		desired.x = bounds.get_center().x
	else:
		desired.x = clampf(desired.x, min_position.x, max_position.x)
	if min_position.y > max_position.y:
		desired.y = bounds.get_center().y
	else:
		desired.y = clampf(desired.y, min_position.y, max_position.y)
	var correction: Vector2 = desired - Vector2(state.raw_position.x, state.raw_position.y)
	var weight: Vector2 = Vector2(
		CameramanDamper.damp(1.0, damping.x, delta),
		CameramanDamper.damp(1.0, damping.y, delta)
	)
	state.position_correction += Vector3(correction.x * weight.x, correction.y * weight.y, 0.0)

func invalidate_bounding_shape_cache() -> void:
	_cache_valid = false

func _get_bounds(camera: Node) -> Rect2:
	var shape_node: Node = camera.get_node_or_null(bounding_shape)
	if shape_node is CollisionShape2D and (shape_node as CollisionShape2D).shape is RectangleShape2D:
		var shape: RectangleShape2D = (shape_node as CollisionShape2D).shape as RectangleShape2D
		var transform: Transform2D = (shape_node as CollisionShape2D).global_transform
		var center: Vector2 = transform * Vector2.ZERO
		var size: Vector2 = shape.size * transform.get_scale().abs()
		_cached_bounds = Rect2(center - size * 0.5, size)
		_cache_valid = true
	elif shape_node is Polygon2D:
		var polygon: PackedVector2Array = (shape_node as Polygon2D).polygon
		if polygon.is_empty():
			return _cached_bounds
		var bounds: Rect2 = Rect2((shape_node as Polygon2D).global_position, Vector2.ZERO)
		for point in polygon:
			bounds = bounds.expand((shape_node as Polygon2D).global_transform * point)
		_cached_bounds = bounds
		_cache_valid = true
	return _cached_bounds
