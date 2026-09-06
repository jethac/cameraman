@tool
class_name CameramanSplineDolly
## BODY-stage component that positions and orients a camera along a Path3D curve.
extends CameramanComponent

enum PositionUnits { DISTANCE, NORMALIZED, KNOT }
enum CameraRotation { DEFAULT, PATH, PATH_NO_ROLL, FOLLOW_TARGET, FOLLOW_TARGET_NO_ROLL }

## Path3D whose curve supplies the camera position and optional rotation.
@export var spline: Path3D
## Position along the spline in meters, normalized units, or knot units.
@export var camera_position: float = 0.0
## Selects how camera_position is interpreted.
@export var position_units: PositionUnits = PositionUnits.DISTANCE
## Local offset from the sampled spline transform.
@export var spline_offset: Vector3 = Vector3.ZERO
## Selects path, target, or existing-state orientation behavior.
@export var camera_rotation: CameraRotation = CameraRotation.DEFAULT
## Optional resource that advances or target-locks camera_position each update.
@export var automatic_dolly: CameramanSplineAutoDolly
## Seconds to reach about 63% of the sampled position per axis; zero snaps immediately.
@export var position_damping: Vector3 = Vector3.ZERO
## Seconds to reach about 63% of sampled orientation; zero snaps immediately.
@export var angular_damping: float = 0.0

func _init() -> void:
	automatic_dolly = CameramanSplineAutoDolly.new()

func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.BODY

func mutate_camera_state(state: CameramanCameraState, delta: float) -> void:
	if spline == null or spline.curve == null:
		return
	var curve: Curve3D = spline.curve
	var length: float = curve.get_baked_length()
	var offset: float = _get_distance(curve, length, delta)
	var sample: Transform3D = curve.sample_baked_with_rotation(offset, true, true)
	var desired_position: Vector3 = spline.to_global(
		sample.origin + sample.basis * spline_offset
	)
	if not vcam.previous_state_is_valid:
		state.raw_position = desired_position
	else:
		state.raw_position += CameramanDamper.damp_vector(
			desired_position - state.raw_position,
			position_damping,
			delta
		)
	var desired_rotation: Quaternion = _get_rotation(sample, state)
	if not vcam.previous_state_is_valid:
		state.raw_orientation = desired_rotation
	else:
		state.raw_orientation = state.raw_orientation.slerp(
			desired_rotation,
			CameramanDamper.damp(1.0, angular_damping, delta)
		)

## Projects an externally forced position back onto the spline.
func force_camera_position(position: Vector3, _rotation: Quaternion) -> void:
	if spline != null and spline.curve != null:
		camera_position = spline.curve.get_closest_offset(spline.to_local(position))

func _get_distance(curve: Curve3D, length: float, delta: float) -> float:
	if automatic_dolly != null and automatic_dolly.enabled:
		if automatic_dolly.mode == CameramanSplineAutoDolly.Mode.FIXED_SPEED:
			camera_position += automatic_dolly.speed * delta
		elif follow_target != null:
			camera_position = curve.get_closest_offset(
				spline.to_local(follow_target.global_position)
			) + automatic_dolly.position_offset
	if position_units == PositionUnits.NORMALIZED:
		if automatic_dolly != null and automatic_dolly.enabled:
			camera_position = fposmod(camera_position, 1.0)
		return clampf(camera_position, 0.0, 1.0) * length
	if automatic_dolly != null and automatic_dolly.enabled and length > 0.0:
		camera_position = fposmod(camera_position, length)
	return clampf(camera_position, 0.0, length)

func _get_rotation(sample: Transform3D, state: CameramanCameraState) -> Quaternion:
	match camera_rotation:
		CameraRotation.PATH:
			return spline.global_transform.basis.get_rotation_quaternion() * sample.basis.get_rotation_quaternion()
		CameraRotation.PATH_NO_ROLL:
			var forward: Vector3 = sample.basis * Vector3.FORWARD
			return Basis.looking_at(forward, state.reference_up, false).get_rotation_quaternion()
		CameraRotation.FOLLOW_TARGET:
			return follow_target.global_basis.get_rotation_quaternion() if follow_target != null else state.raw_orientation
		CameraRotation.FOLLOW_TARGET_NO_ROLL:
			if follow_target == null:
				return state.raw_orientation
			var target_forward: Vector3 = follow_target.global_basis * Vector3.FORWARD
			return Basis.looking_at(target_forward, state.reference_up, false).get_rotation_quaternion()
	return state.raw_orientation
