@tool
class_name CameramanFollow
## Provides the follow camera pipeline component.
## Key properties include `follow_offset`, `binding_mode`, `position_damping`, and related settings, which configure
## its behavior.
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

## Configures the follow offset used by this type.
@export var follow_offset: Vector3 = Vector3.ZERO
## Selects the binding mode behavior.
@export var binding_mode: BindingMode = BindingMode.LOCK_TO_TARGET_WITH_WORLD_UP
## Controls the damping applied to position.
@export var position_damping: Vector3 = Vector3.ZERO
## Controls the damping applied to rotation.
@export var rotation_damping: Vector3 = Vector3.ZERO
## Controls the damping applied to angular mode.
@export var angular_damping_mode: AngularDampingMode = AngularDampingMode.EULER
## Controls the damping applied to quaternion.
@export var quaternion_damping: float = 0.0

var _assigned_basis: Basis
var _assigned_target: Node3D
var _assigned_captured: bool = false
var _previous_position: Vector3
var _previous_rotation: Quaternion = Quaternion.IDENTITY

## Returns the pipeline stage handled by this type.
func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.BODY

## Applies this component's camera-state mutation for the current pipeline step.
func mutate_camera_state(state: CameramanCameraState, delta: float) -> void:
	if _assigned_target != follow_target:
		_assigned_target = follow_target
		_assigned_basis = Basis()
		_assigned_captured = false
	if follow_target == null:
		return
	var target_transform: Transform3D = follow_target.global_transform
	var desired_position: Vector3 = target_transform.origin
	var desired_rotation: Quaternion = target_transform.basis.get_rotation_quaternion()
	match binding_mode:
		BindingMode.WORLD_SPACE:
			desired_position += follow_offset
		BindingMode.LOCK_TO_TARGET_ON_ASSIGN:
			if not _assigned_captured:
				_assigned_basis = target_transform.basis
				_assigned_captured = true
			desired_position += _assigned_basis * follow_offset
		BindingMode.LOCK_TO_TARGET_WITH_WORLD_UP:
			desired_rotation = CameramanTargetTracker.get_reference_orientation(
				state,
				CameramanTargetTracker.BindingMode.LOCK_TO_TARGET_WITH_WORLD_UP,
				follow_target
			)
			desired_position += desired_rotation * follow_offset
		BindingMode.LOCK_TO_TARGET_NO_ROLL:
			desired_rotation = CameramanTargetTracker.get_reference_orientation(
				state,
				CameramanTargetTracker.BindingMode.LOCK_TO_TARGET_NO_ROLL,
				follow_target
			)
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

## Handles the target object warped event.
func on_target_object_warped(target: Node3D, delta: Vector3) -> void:
	if target == follow_target:
		_previous_position += delta

## Forces the camera and its pipeline state to a position and rotation.
func force_camera_position(position: Vector3, rotation: Quaternion) -> void:
	_previous_position = position
	_previous_rotation = rotation

## Returns the longest damping time configured by this type.
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
