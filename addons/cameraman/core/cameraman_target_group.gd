@tool
class_name CameramanTargetGroup
## Aggregates weighted target nodes for group framing, bounds, and screen-space composition.
extends Node3D

enum PositionMode { GROUP_CENTER, GROUP_AVERAGE }
enum RotationMode { MANUAL, GROUP_AVERAGE }
enum UpdateMethod { PROCESS, PHYSICS, LATE }

## Weighted target members used to calculate the group center and bounds.
@export var members: Array[CameramanTargetGroupMember] = []
## Selects the group position calculation.
@export var position_mode: PositionMode = PositionMode.GROUP_CENTER
## Selects whether group orientation is manual or target-derived.
@export var rotation_mode: RotationMode = RotationMode.MANUAL
## Selects process or physics updates for group aggregation.
@export var update_method: UpdateMethod = UpdateMethod.PROCESS

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if update_method == UpdateMethod.PROCESS or update_method == UpdateMethod.LATE:
		update_group()

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if update_method == UpdateMethod.PHYSICS:
		update_group()

## Resolves members and recomputes group position and orientation.
func update_group() -> void:
	for member in members:
		if member != null:
			member.resolve(self)
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
	_resolve_members()
	for member in members:
		if member != null and member.target != null and member.weight > 0.0:
			return false
	return true

func add_member(
	target_node: Node3D,
	weight_value: float = 1.0,
	radius_value: float = 0.0
) -> CameramanTargetGroupMember:
	var member: CameramanTargetGroupMember = CameramanTargetGroupMember.new()
	member.target = target_node
	member.weight = weight_value
	member.radius = radius_value
	members.append(member)
	return member

func remove_member(target_node: Node3D) -> void:
	for index in range(members.size() - 1, -1, -1):
		var member: CameramanTargetGroupMember = members[index]
		if member != null and member.target == target_node:
			members.remove_at(index)

func find_member(target_node: Node3D) -> CameramanTargetGroupMember:
	for member in members:
		if member != null and member.target == target_node:
			return member
	return null

## Returns a center and radius enclosing all weighted target members.
func get_sphere() -> Array[Variant]:
	_resolve_members()
	var center: Vector3 = Vector3.ZERO
	var total_weight: float = 0.0
	if position_mode == PositionMode.GROUP_CENTER:
		var bounds: AABB = get_bounding_box()
		center = to_global(bounds.get_center())
	for member in members:
		if member == null or member.target == null or member.weight <= 0.0:
			continue
		if position_mode == PositionMode.GROUP_AVERAGE:
			center += member.target.global_position * member.weight
			total_weight += member.weight
	if position_mode == PositionMode.GROUP_AVERAGE and total_weight > 0.0:
		center /= total_weight
	var radius: float = 0.0
	for member in members:
		if member == null or member.target == null or member.weight <= 0.0:
			continue
		radius = maxf(radius, center.distance_to(member.target.global_position) + member.radius)
	return [center, radius]

## Returns an AABB enclosing target positions and member radii.
func get_bounding_box() -> AABB:
	_resolve_members()
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

## Returns member bounds transformed into the supplied view space.
func get_view_space_bounding_box(view_transform: Transform3D) -> AABB:
	_resolve_members()
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

func _resolve_members() -> void:
	for member in members:
		if member != null:
			member.resolve(self)

## Returns horizontal and vertical angular bounds from an observer transform.
func get_view_space_angular_bounds(observer: Transform3D) -> Array[Variant]:
	var minimum: Vector2 = Vector2(INF, INF)
	var maximum: Vector2 = Vector2(-INF, -INF)
	for member in members:
		if member == null or member.resolve(self) == null or member.weight <= 0.0:
			continue
		var local: Vector3 = observer * member.target.global_position
		var depth: float = maxf(-local.z, 0.001)
		var angle: Vector2 = Vector2(atan2(local.x, depth), atan2(local.y, depth))
		minimum.x = minf(minimum.x, angle.x)
		minimum.y = minf(minimum.y, angle.y)
		maximum.x = maxf(maximum.x, angle.x)
		maximum.y = maxf(maximum.y, angle.y)
	return [minimum, maximum]
