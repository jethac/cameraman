@tool
class_name CameramanCameraState
## Stores raw values, corrections, final output values, and custom blendable state for one frame.
extends RefCounted

static var aspect_ratio: float = 16.0 / 9.0

var lens: CameramanLens = CameramanLens.new()
var reference_up: Vector3 = Vector3.UP
var reference_look_at: Vector3 = CameramanCore.NO_POINT
var raw_position: Vector3 = Vector3.ZERO
var raw_orientation: Quaternion = Quaternion.IDENTITY
var position_correction: Vector3 = Vector3.ZERO
var orientation_correction: Quaternion = Quaternion.IDENTITY
var rotation_damping_bypass: Quaternion = Quaternion.IDENTITY
var shot_quality: float = 1.0
var blend_hint: int = 0
var custom_blendables: Array[Dictionary] = []

## Returns true when the state contains a valid corrected look-at target.
func has_look_at() -> bool:
	return is_finite(reference_look_at.x) and is_finite(reference_look_at.y) and is_finite(reference_look_at.z)

## Returns raw_position plus position_correction.
func get_final_position() -> Vector3:
	return raw_position + position_correction

## Returns raw_orientation composed with orientation_correction.
func get_final_orientation() -> Quaternion:
	return (raw_orientation * orientation_correction).normalized()

## Returns look_at plus look_at_correction when a look-at target exists.
func get_corrected_look_at() -> Vector3:
	if not has_look_at():
		return CameramanCore.NO_POINT
	return reference_look_at + position_correction

## Stores a blendable value and weight for custom state interpolation.
func add_custom_blendable(object: Object, weight: float) -> void:
	if object == null or custom_blendables.size() >= 8:
		return
	custom_blendables.append({"object": object, "weight": weight})

static func create_default(up: Vector3 = Vector3.UP) -> CameramanCameraState:
	var state: CameramanCameraState = CameramanCameraState.new()
	state.reference_up = up.normalized() if up.length_squared() > 0.0 else Vector3.UP
	return state

static func lerp(from: CameramanCameraState, to: CameramanCameraState, weight: float) -> CameramanCameraState:
	var result: CameramanCameraState = CameramanCameraState.create_default()
	var t: float = clampf(weight, 0.0, 1.0)
	result.lens = from.lens.lerp(to.lens, t)
	result.reference_up = from.reference_up.slerp(to.reference_up, t).normalized()
	var both_look_at: bool = from.has_look_at() and to.has_look_at()
	var hint: int = from.blend_hint | to.blend_hint
	var position: Vector3 = from.raw_position.lerp(to.raw_position, t)
	if both_look_at and (hint & CameramanCore.BlendHint.SPHERICAL_POSITION) != 0:
		var look_at: Vector3 = from.reference_look_at.lerp(to.reference_look_at, t)
		var from_offset: Vector3 = from.raw_position - from.reference_look_at
		var to_offset: Vector3 = to.raw_position - to.reference_look_at
		var direction: Vector3 = from_offset.normalized().slerp(to_offset.normalized(), t).normalized()
		var magnitude: float = lerpf(from_offset.length(), to_offset.length(), t)
		position = look_at + direction * magnitude
	elif both_look_at and (hint & CameramanCore.BlendHint.CYLINDRICAL_POSITION) != 0:
		var look_at_cyl: Vector3 = from.reference_look_at.lerp(to.reference_look_at, t)
		var from_offset_cyl: Vector3 = from.raw_position - from.reference_look_at
		var to_offset_cyl: Vector3 = to.raw_position - to.reference_look_at
		var up: Vector3 = result.reference_up.normalized()
		if up.length_squared() < 0.000001:
			up = Vector3.UP
		var from_up: float = from_offset_cyl.dot(up)
		var to_up: float = to_offset_cyl.dot(up)
		var from_radial: Vector3 = from_offset_cyl - up * from_up
		var to_radial: Vector3 = to_offset_cyl - up * to_up
		var radial: Vector3
		if from_radial.length_squared() < 0.000001:
			radial = to_radial.normalized()
		elif to_radial.length_squared() < 0.000001:
			radial = from_radial.normalized()
		else:
			radial = from_radial.normalized().slerp(to_radial.normalized(), t).normalized()
		var radius: float = lerpf(from_radial.length(), to_radial.length(), t)
		var up_offset: float = lerpf(from_up, to_up, t)
		position = look_at_cyl + radial * radius + up * up_offset
	result.raw_position = position
	result.reference_look_at = _lerp_look_at(from, to, result.lens, position, t, hint)
	var orientation: Quaternion = from.raw_orientation.slerp(to.raw_orientation, t).normalized()
	if both_look_at and (hint & CameramanCore.BlendHint.IGNORE_TARGET) == 0:
		orientation = _aim_with_screen_offset(
			position,
			result.reference_look_at,
			result.reference_up,
			from,
			to,
			t,
			result.lens
		)
	result.raw_orientation = orientation
	result.position_correction = from.position_correction.lerp(to.position_correction, t)
	result.orientation_correction = from.orientation_correction.slerp(to.orientation_correction, t).normalized()
	result.rotation_damping_bypass = from.rotation_damping_bypass.slerp(
		to.rotation_damping_bypass, t
	).normalized()
	result.shot_quality = lerpf(from.shot_quality, to.shot_quality, t)
	result.blend_hint = hint
	for entry in from.custom_blendables:
		result.add_custom_blendable(entry.object, float(entry.weight) * (1.0 - t))
	for entry in to.custom_blendables:
		result.add_custom_blendable(entry.object, float(entry.weight) * t)
	return result

static func _lerp_look_at(
	from: CameramanCameraState,
	to: CameramanCameraState,
	lens: CameramanLens,
	position: Vector3,
	weight: float,
	hint: int
) -> Vector3:
	if not from.has_look_at():
		return to.reference_look_at if to.has_look_at() else CameramanCore.NO_POINT
	if not to.has_look_at():
		return from.reference_look_at
	if (hint & CameramanCore.BlendHint.SCREEN_SPACE_AIM_WHEN_TARGETS_DIFFER) == 0:
		return from.reference_look_at.lerp(to.reference_look_at, weight)
	var from_screen: Vector2 = _screen_offset(from, from.reference_look_at)
	var to_screen: Vector2 = _screen_offset(to, to.reference_look_at)
	var screen: Vector2 = from_screen.lerp(to_screen, weight)
	var distance: float = lerpf(
		from.raw_position.distance_to(from.reference_look_at),
		to.raw_position.distance_to(to.reference_look_at),
		weight
	)
	var direction: Vector3 = _screen_direction(screen, lens)
	var orientation: Quaternion = from.raw_orientation.slerp(to.raw_orientation, weight).normalized()
	return position + (orientation * direction).normalized() * distance

static func _screen_offset(state: CameramanCameraState, target: Vector3) -> Vector2:
	var local: Vector3 = state.raw_orientation.inverse() * (target - state.raw_position)
	if state.lens.is_orthographic():
		return Vector2(
			local.x / maxf(state.lens.orthographic_size * aspect_ratio, 0.001),
			local.y / maxf(state.lens.orthographic_size, 0.001)
		)
	var depth: float = maxf(-local.z, 0.001)
	var half_height: float = tan(deg_to_rad(state.lens.fov_degrees) * 0.5)
	var half_width: float = half_height * aspect_ratio
	return Vector2(local.x / depth / half_width, local.y / depth / half_height)

static func _screen_direction(screen: Vector2, lens: CameramanLens) -> Vector3:
	if lens.is_orthographic():
		return Vector3(screen.x * aspect_ratio, screen.y, -1.0).normalized()
	var half_height: float = tan(deg_to_rad(lens.fov_degrees) * 0.5)
	var half_width: float = half_height * aspect_ratio
	return Vector3(screen.x * half_width, screen.y * half_height, -1.0).normalized()

static func _aim_with_screen_offset(
	position: Vector3,
	target: Vector3,
	up: Vector3,
	from: CameramanCameraState,
	to: CameramanCameraState,
	weight: float,
	lens: CameramanLens
) -> Quaternion:
	var from_screen: Vector2 = _screen_offset(from, from.reference_look_at)
	var to_screen: Vector2 = _screen_offset(to, to.reference_look_at)
	var screen: Vector2 = from_screen.lerp(to_screen, weight)
	var direction: Vector3 = (target - position).normalized()
	if direction.length_squared() < 0.000001:
		return from.raw_orientation.slerp(to.raw_orientation, weight).normalized()
	var target_basis: Basis = Basis.looking_at(direction, up, false)
	var local_direction: Vector3 = _screen_direction(screen, lens)
	var forward: Vector3 = Vector3.FORWARD
	var screen_rotation: Quaternion = Quaternion(local_direction, forward)
	return (target_basis.get_rotation_quaternion() * screen_rotation).normalized()
