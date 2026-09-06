class_name CameramanFollow
extends CameramanComponent

enum BindingMode {
	LOCK_TO_TARGET_ON_ASSIGN,
	LOCK_TO_TARGET_WITH_WORLD_UP,
	LOCK_TO_TARGET_NO_ROLL,
	LOCK_TO_TARGET,
	WORLD_SPACE,
	LAZY_FOLLOW
}
enum AngularDampingMode { EULER, QUATERNION }

@export var follow_offset: Vector3 = Vector3.ZERO
@export var binding_mode: BindingMode = BindingMode.LOCK_TO_TARGET_WITH_WORLD_UP
@export var position_damping: Vector3 = Vector3.ZERO
@export var rotation_damping: Vector3 = Vector3.ZERO
@export var angular_damping_mode: AngularDampingMode = AngularDampingMode.EULER
@export var quaternion_damping: float = 0.0

var _assigned_basis: Basis
var _previous_position: Vector3
var _previous_rotation: Quaternion = Quaternion.IDENTITY

func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.BODY

func mutate_camera_state(state: CameramanCameraState, delta: float) -> void:
	if follow_target == null:
		return
	var target_transform: Transform3D = follow_target.global_transform
	var desired_position: Vector3 = target_transform.origin
	var desired_rotation: Quaternion = target_transform.basis.get_rotation_quaternion()
	match binding_mode:
		BindingMode.WORLD_SPACE:
			desired_position += follow_offset
		BindingMode.LOCK_TO_TARGET_ON_ASSIGN:
			if _assigned_basis == Basis():
				_assigned_basis = target_transform.basis
			desired_position += _assigned_basis * follow_offset
		BindingMode.LOCK_TO_TARGET_WITH_WORLD_UP:
			desired_rotation = _world_up_rotation(desired_rotation, state.reference_up, true)
			desired_position += desired_rotation * follow_offset
		BindingMode.LOCK_TO_TARGET_NO_ROLL:
			desired_rotation = _world_up_rotation(desired_rotation, state.reference_up, false)
			desired_position += desired_rotation * follow_offset
		BindingMode.LOCK_TO_TARGET:
			desired_position += desired_rotation * follow_offset
		BindingMode.LAZY_FOLLOW:
			var heading: Vector3 = (follow_target.global_position - state.raw_position)
			heading = heading.slide(state.reference_up)
			if heading.length_squared() > 0.000001:
				var lazy_basis: Basis = Basis.looking_at(
					-heading.normalized(),
					state.reference_up,
					false
				)
				desired_position += lazy_basis * follow_offset
	if not vcam.previous_state_is_valid:
		state.raw_position = desired_position
	else:
		var difference: Vector3 = desired_position - state.raw_position
		state.raw_position += CameramanDamper.damp_vector(difference, position_damping, delta)
	if binding_mode != BindingMode.WORLD_SPACE:
		if angular_damping_mode == AngularDampingMode.QUATERNION:
			var rotation_weight: float = CameramanDamper.damp(1.0, quaternion_damping, delta)
			state.raw_orientation = state.raw_orientation.slerp(desired_rotation, rotation_weight)
		elif vcam.previous_state_is_valid:
			var rotation_weight_euler: Vector3 = Vector3(
				CameramanDamper.damp(1.0, rotation_damping.x, delta),
				CameramanDamper.damp(1.0, rotation_damping.y, delta),
				CameramanDamper.damp(1.0, rotation_damping.z, delta)
			)
			var current_euler: Vector3 = state.raw_orientation.get_euler()
			var desired_euler: Vector3 = desired_rotation.get_euler()
			var angle_delta: Vector3 = Vector3(
				wrapf(desired_euler.x - current_euler.x, -PI, PI),
				wrapf(desired_euler.y - current_euler.y, -PI, PI),
				wrapf(desired_euler.z - current_euler.z, -PI, PI)
			)
			state.raw_orientation = Quaternion.from_euler(Vector3(
				current_euler.x + angle_delta.x * rotation_weight_euler.x,
				current_euler.y + angle_delta.y * rotation_weight_euler.y,
				current_euler.z + angle_delta.z * rotation_weight_euler.z
			))
		else:
			state.raw_orientation = desired_rotation
	_previous_position = desired_position
	_previous_rotation = desired_rotation

func on_target_object_warped(target: Node3D, delta: Vector3) -> void:
	if target == follow_target:
		_previous_position += delta

func force_camera_position(position: Vector3, rotation: Quaternion) -> void:
	_previous_position = position
	_previous_rotation = rotation

func get_max_damp_time() -> float:
	return maxf(
		CameramanDamper.max_damp_time(position_damping),
		CameramanDamper.max_damp_time(rotation_damping)
	)

func _world_up_rotation(rotation: Quaternion, up: Vector3, flatten: bool) -> Quaternion:
	var forward: Vector3 = rotation * Vector3.FORWARD
	if flatten:
		forward = forward.slide(up).normalized()
	if forward.length_squared() < 0.000001:
		forward = Vector3.FORWARD.slide(up).normalized()
	return Basis.looking_at(forward, up, false).get_rotation_quaternion()
