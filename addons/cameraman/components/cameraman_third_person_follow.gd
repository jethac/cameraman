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
	var desired: Vector3 = hand - target_rotation * Vector3(0.0, 0.0, desired_distance)
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

func _get_obstacle_distance(hand: Vector3, rotation: Quaternion, delta: float) -> float:
	var desired_distance: float = camera_distance
	if avoid_obstacles == null or not avoid_obstacles.enabled or not is_inside_tree():
		return desired_distance
	var end: Vector3 = hand - rotation * Vector3(0.0, 0.0, desired_distance)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(hand, end)
	query.collision_mask = avoid_obstacles.collision_mask
	var world_node: Node3D = vcam as Node3D
	if world_node == null or world_node.get_world_3d() == null:
		return desired_distance
	var hit: Dictionary = world_node.get_world_3d().direct_space_state.intersect_ray(query)
	var target_distance: float = desired_distance
	if not hit.is_empty():
		target_distance = maxf(
			(hand as Vector3).distance_to(hit["position"] as Vector3) - avoid_obstacles.camera_radius,
			0.05
		)
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
