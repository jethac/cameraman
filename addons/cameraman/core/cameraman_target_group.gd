class_name CameramanTargetGroup
extends Node3D

enum PositionMode { GROUP_CENTER, GROUP_AVERAGE }
enum RotationMode { MANUAL, GROUP_AVERAGE }

@export var members: Array[CameramanTargetGroupMember] = []
@export var position_mode: PositionMode = PositionMode.GROUP_CENTER
@export var rotation_mode: RotationMode = RotationMode.MANUAL
@export_enum("PROCESS", "PHYSICS", "MANUAL") var update_method: int = 0

func _process(_delta: float) -> void:
	if update_method == 0:
		update_group()

func _physics_process(_delta: float) -> void:
	if update_method == 1:
		update_group()

func update_group() -> void:
	var sphere: Array[Variant] = get_sphere()
	if not is_empty():
		global_position = sphere[0] as Vector3
	if rotation_mode == RotationMode.GROUP_AVERAGE:
		var average: Vector3 = Vector3.ZERO
		var count: int = 0
		for member in members:
			if member != null and member.target != null:
				average += member.target.global_basis.z
				count += 1
		if count > 0 and average.length_squared() > 0.000001:
			look_at(global_position + average.normalized(), Vector3.UP)

func is_empty() -> bool:
	for member in members:
		if member != null and member.target != null and member.weight > 0.0:
			return false
	return true

func get_sphere() -> Array[Variant]:
	var center: Vector3 = Vector3.ZERO
	var total_weight: float = 0.0
	for member in members:
		if member == null or member.target == null or member.weight <= 0.0:
			continue
		center += member.target.global_position * member.weight
		total_weight += member.weight
	if total_weight > 0.0:
		center /= total_weight
	var radius: float = 0.0
	for member in members:
		if member == null or member.target == null or member.weight <= 0.0:
			continue
		radius = maxf(radius, center.distance_to(member.target.global_position) + member.radius)
	return [center, radius]

func get_bounding_box() -> AABB:
	if is_empty():
		return AABB(global_position, Vector3.ZERO)
	var first: bool = true
	var bounds: AABB = AABB()
	for member in members:
		if member == null or member.target == null or member.weight <= 0.0:
			continue
		var point: Vector3 = member.target.global_position
		var local_point: Vector3 = to_local(point)
		var extent: Vector3 = Vector3.ONE * member.radius
		var point_box: AABB = AABB(local_point - extent, extent * 2.0)
		bounds = point_box if first else bounds.merge(point_box)
		first = false
	return bounds

func get_view_space_bounding_box(view_transform: Transform3D) -> AABB:
	if is_empty():
		return AABB(Vector3.ZERO, Vector3.ZERO)
	var first: bool = true
	var bounds: AABB = AABB()
	for member in members:
		if member == null or member.target == null or member.weight <= 0.0:
			continue
		var point: Vector3 = view_transform * member.target.global_position
		var extent: Vector3 = Vector3.ONE * member.radius
		var point_box: AABB = AABB(point - extent, extent * 2.0)
		bounds = point_box if first else bounds.merge(point_box)
		first = false
	return bounds
