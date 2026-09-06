class_name CameramanConfiner3D
extends CameramanExtension

@export var bounding_volume: NodePath
@export var damping: Vector3 = Vector3.ZERO
@export var slowing_distance: float = 0.0

func post_pipeline_stage_callback(
	camera: Node,
	stage: CameramanCore.Stage,
	state: CameramanCameraState,
	delta: float
) -> void:
	if stage != CameramanCore.Stage.BODY:
		return
	var shape_node: CollisionShape3D = camera.get_node_or_null(bounding_volume) as CollisionShape3D
	if shape_node == null or shape_node.shape == null:
		return
	var local: Vector3 = shape_node.global_transform.inverse() * state.raw_position
	var corrected: Vector3 = _closest_point_inside(shape_node.shape, local)
	var world_corrected: Vector3 = shape_node.global_transform * corrected
	var correction: Vector3 = world_corrected - state.raw_position
	var weight: Vector3 = Vector3(
		CameramanDamper.damp(1.0, damping.x, delta),
		CameramanDamper.damp(1.0, damping.y, delta),
		CameramanDamper.damp(1.0, damping.z, delta)
	)
	state.position_correction += Vector3(correction.x * weight.x, correction.y * weight.y, correction.z * weight.z)

func _closest_point_inside(shape: Shape3D, point: Vector3) -> Vector3:
	if shape is BoxShape3D:
		var box: BoxShape3D = shape as BoxShape3D
		var half: Vector3 = box.size * 0.5
		return Vector3(clampf(point.x, -half.x, half.x), clampf(point.y, -half.y, half.y), clampf(point.z, -half.z, half.z))
	if shape is SphereShape3D:
		var sphere: SphereShape3D = shape as SphereShape3D
		return point.limit_length(sphere.radius)
	if shape is CapsuleShape3D:
		var capsule: CapsuleShape3D = shape as CapsuleShape3D
		var half_height: float = maxf(capsule.height * 0.5 - capsule.radius, 0.0)
		var y: float = clampf(point.y, -half_height, half_height)
		var radial: Vector2 = Vector2(point.x, point.z)
		if radial.length() > capsule.radius:
			radial = radial.normalized() * capsule.radius
		return Vector3(radial.x, y, radial.y)
	if shape is CylinderShape3D:
		var cylinder: CylinderShape3D = shape as CylinderShape3D
		var radial: Vector2 = Vector2(point.x, point.z)
		if radial.length() > cylinder.radius:
			radial = radial.normalized() * cylinder.radius
		return Vector3(radial.x, clampf(point.y, -cylinder.height * 0.5, cylinder.height * 0.5), radial.y)
	if shape is ConvexPolygonShape3D:
		var convex: ConvexPolygonShape3D = shape as ConvexPolygonShape3D
		if not convex.points.is_empty():
			var bounds: AABB = AABB(convex.points[0], Vector3.ZERO)
			for point_value in convex.points:
				bounds = bounds.expand(point_value)
			return Vector3(
				clampf(point.x, bounds.position.x, bounds.end.x),
				clampf(point.y, bounds.position.y, bounds.end.y),
				clampf(point.z, bounds.position.z, bounds.end.z)
			)
	return point
