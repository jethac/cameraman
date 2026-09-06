class_name CameramanThirdPersonFollow
extends CameramanComponent

@export var damping: Vector3 = Vector3.ZERO
@export var shoulder_offset: Vector3 = Vector3(0.5, 1.5, 0.0)
@export var vertical_arm_length: float = 0.0
@export_range(0.0, 1.0) var camera_side: float = 1.0
@export var camera_distance: float = 4.0
@export var avoid_obstacles: CameramanObstacleAvoidance

var _collision_distance: float = -1.0

func _init() -> void:
	avoid_obstacles = CameramanObstacleAvoidance.new()

func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.BODY

func mutate_camera_state(state: CameramanCameraState, delta: float) -> void:
	var target: Node3D = follow_target
	if target == null:
		return
	var target_rotation: Quaternion = target.global_basis.get_rotation_quaternion()
	var side_offset: Vector3 = shoulder_offset
	side_offset.x *= lerpf(-1.0, 1.0, camera_side)
	var root: Vector3 = target.global_position
	var shoulder: Vector3 = root + target_rotation * side_offset
	var hand: Vector3 = shoulder + target_rotation * Vector3(0.0, vertical_arm_length, 0.0)
	var desired_distance: float = _get_obstacle_distance(hand, target_rotation, delta)
	var desired: Vector3 = hand + target_rotation * Vector3(0.0, 0.0, desired_distance)
	if not vcam.previous_state_is_valid:
		state.raw_position = desired
	else:
		state.raw_position += CameramanDamper.damp_vector(desired - state.raw_position, damping, delta)
	if not vcam.previous_state_is_valid:
		state.raw_orientation = target_rotation
	else:
		var rotation_weight: float = CameramanDamper.damp(1.0, damping.y, delta)
		state.raw_orientation = state.raw_orientation.slerp(target_rotation, rotation_weight)

func get_rig_positions() -> Array[Vector3]:
	var target: Node3D = follow_target
	if target == null:
		return [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
	var rotation: Quaternion = target.global_basis.get_rotation_quaternion()
	var side_offset: Vector3 = shoulder_offset
	side_offset.x *= lerpf(-1.0, 1.0, camera_side)
	var root: Vector3 = target.global_position
	var shoulder: Vector3 = root + rotation * side_offset
	var hand: Vector3 = shoulder + rotation * Vector3(0.0, vertical_arm_length, 0.0)
	return [root, shoulder, hand]

func force_camera_position(position: Vector3, _rotation: Quaternion) -> void:
	var rig: Array[Vector3] = get_rig_positions()
	if rig.size() >= 3:
		camera_distance = rig[2].distance_to(position)

func on_target_object_warped(target: Node3D, _delta: Vector3) -> void:
	if target == follow_target:
		_collision_distance = -1.0

func on_transition_from_camera(from: Object, _world_up: Vector3, _delta: float) -> bool:
	if (
		vcam == null
		or (int(vcam.get("blend_hint")) & CameramanCore.BlendHint.INHERIT_POSITION) == 0
		or from == null
		or not from.has_method("get_state")
	):
		return false
	var previous: CameramanCameraState = from.get_state()
	force_camera_position(previous.get_final_position(), previous.get_final_orientation())
	return true

func _get_obstacle_distance(hand: Vector3, rotation: Quaternion, delta: float) -> float:
	var desired_distance: float = camera_distance
	if avoid_obstacles == null or not avoid_obstacles.enabled or not is_inside_tree():
		return desired_distance
	var world_node: Node3D = vcam as Node3D
	if world_node == null or world_node.get_world_3d() == null:
		return desired_distance
	var target_distance: float = _cast_camera_path(world_node, hand, rotation, desired_distance)
	if _collision_distance < 0.0:
		_collision_distance = target_distance
	var damp_time: float = (
		avoid_obstacles.damping_into
		if target_distance < _collision_distance
		else avoid_obstacles.damping_from_collision
	)
	_collision_distance += (target_distance - _collision_distance) * (
		CameramanDamper.damp(1.0, damp_time, delta)
	)
	return _collision_distance

func _cast_camera_path(
	world_node: Node3D,
	hand: Vector3,
	rotation: Quaternion,
	distance: float
) -> float:
	var end: Vector3 = hand + rotation * Vector3(0.0, 0.0, distance)
	var exclusions: Array[RID] = _get_collision_exclusions()
	if avoid_obstacles.camera_radius <= 0.0:
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(hand, end)
		query.collision_mask = avoid_obstacles.collision_mask
		query.exclude = exclusions
		var hit: Dictionary = _intersect_ray_ignoring_groups(
			world_node.get_world_3d().direct_space_state,
			query,
			exclusions
		)
		return (
			maxf(hand.distance_to(hit["position"] as Vector3), 0.05)
			if not hit.is_empty()
			else distance
		)
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = avoid_obstacles.camera_radius
	var first_fraction: float = _cast_shape(world_node, sphere, hand, get_rig_positions()[1], exclusions)
	if first_fraction < 1.0:
		return 0.05
	var second_fraction: float = _cast_shape(world_node, sphere, hand, end, exclusions)
	return maxf(distance * second_fraction, 0.05)

func _cast_shape(
	world_node: Node3D,
	shape: Shape3D,
	start: Vector3,
	end: Vector3,
	exclusions: Array[RID]
) -> float:
	var space: PhysicsDirectSpaceState3D = world_node.get_world_3d().direct_space_state
	var filtered_exclusions: Array[RID] = exclusions.duplicate()
	var collect_query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	collect_query.shape = shape
	collect_query.transform = Transform3D(Basis.IDENTITY, start)
	collect_query.motion = end - start
	collect_query.collision_mask = avoid_obstacles.collision_mask
	collect_query.exclude = filtered_exclusions
	for hit in space.intersect_shape(collect_query, 32):
		var collider: Object = hit.get("collider") as Object
		if _is_ignored_group(collider):
			_add_collision_exclusion(filtered_exclusions, collider)
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, start)
	query.motion = end - start
	query.collision_mask = avoid_obstacles.collision_mask
	query.exclude = filtered_exclusions
	var result: PackedFloat32Array = space.cast_motion(query)
	return result[0] if not result.is_empty() else 1.0

func _get_collision_exclusions() -> Array[RID]:
	var result: Array[RID] = []
	var target: Node3D = follow_target
	if target == null:
		return result
	var collision_target: CollisionObject3D = target as CollisionObject3D
	var ancestor: Node = target.get_parent()
	while collision_target == null and ancestor != null:
		collision_target = ancestor as CollisionObject3D
		ancestor = ancestor.get_parent()
	if collision_target != null:
		_add_collision_exclusion(result, collision_target)
	_add_collision_descendants(target, result)
	return result

func _add_collision_descendants(node: Node, exclusions: Array[RID]) -> void:
	for child in node.get_children():
		var collision: CollisionObject3D = child as CollisionObject3D
		if collision != null:
			_add_collision_exclusion(exclusions, collision)
		_add_collision_descendants(child, exclusions)

func _add_collision_exclusion(exclusions: Array[RID], collider: Object) -> void:
	if collider is CollisionObject3D:
		var rid: RID = (collider as CollisionObject3D).get_rid()
		if not exclusions.has(rid):
			exclusions.append(rid)

func _intersect_ray_ignoring_groups(
	space: PhysicsDirectSpaceState3D,
	query: PhysicsRayQueryParameters3D,
	exclusions: Array[RID]
) -> Dictionary:
	var filtered_exclusions: Array[RID] = exclusions.duplicate()
	for _index in 4:
		query.exclude = filtered_exclusions
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty() or not _is_ignored_group(hit.get("collider") as Object):
			return hit
		_add_collision_exclusion(filtered_exclusions, hit.get("collider") as Object)
	return {}

func _is_ignored_group(collider: Object) -> bool:
	if collider == null or not collider is Node:
		return false
	var group_name: StringName = avoid_obstacles.ignore_group
	if group_name.is_empty():
		group_name = avoid_obstacles.ignore_tag_group_name
	if group_name.is_empty():
		return false
	var node: Node = collider as Node
	while node != null:
		if node.is_in_group(group_name):
			return true
		node = node.get_parent()
	return false
