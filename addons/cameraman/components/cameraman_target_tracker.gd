class_name CameramanTargetTracker
extends RefCounted

enum BindingMode {
	LOCK_TO_TARGET_ON_ASSIGN,
	LOCK_TO_TARGET_WITH_WORLD_UP,
	LOCK_TO_TARGET_NO_ROLL,
	LOCK_TO_TARGET,
	WORLD_SPACE
}

static func get_reference_orientation(
	state: CameramanCameraState,
	binding_mode: int,
	target: Node3D
) -> Quaternion:
	if target == null or binding_mode == BindingMode.WORLD_SPACE:
		return Quaternion.IDENTITY
	var target_rotation: Quaternion = target.global_basis.get_rotation_quaternion()
	if binding_mode == BindingMode.LOCK_TO_TARGET_WITH_WORLD_UP:
		return _world_up_rotation(target_rotation, state.reference_up, true)
	if binding_mode == BindingMode.LOCK_TO_TARGET_NO_ROLL:
		return _world_up_rotation(target_rotation, state.reference_up, false)
	return target_rotation

static func track(
	state: CameramanCameraState,
	target: Node3D,
	binding_mode: int,
	offset: Vector3,
	damping: Vector3,
	delta: float,
	previous_valid: bool
) -> Dictionary:
	if target == null:
		return {}
	var orientation: Quaternion = get_reference_orientation(state, binding_mode, target)
	var position: Vector3 = target.global_position
	if binding_mode == BindingMode.WORLD_SPACE:
		position += offset
	else:
		position += orientation * offset
	if not previous_valid:
		state.raw_position = position
	else:
		state.raw_position += CameramanDamper.damp_vector(position - state.raw_position, damping, delta)
	return {"position": position, "orientation": orientation}

static func _world_up_rotation(rotation: Quaternion, up: Vector3, flatten: bool) -> Quaternion:
	var forward: Vector3 = rotation * Vector3.FORWARD
	if flatten:
		forward = forward.slide(up).normalized()
	if forward.length_squared() < 0.000001:
		forward = Vector3.FORWARD.slide(up).normalized()
	return Basis.looking_at(forward, up, false).get_rotation_quaternion()
