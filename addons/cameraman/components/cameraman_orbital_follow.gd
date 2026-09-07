@tool
class_name CameramanOrbitalFollow
## BODY-stage component that places a camera on a configurable orbit around its follow target.
extends CameramanComponent

enum OrbitStyle { SPHERE, THREE_RING }
enum RecenteringTarget {
	NONE,
	AXIS_CENTER,
	PARENT_HEADING,
	PARENT_FORWARD,
	TRACKING_TARGET_FORWARD,
	LOOK_AT_TARGET_FORWARD
}

## Selects spherical, three-ring, or custom orbital radius behavior.
@export var orbit_style: OrbitStyle = OrbitStyle.SPHERE
## Radius in meters for spherical orbital mode.
@export var radius: float = 5.0
## Vertical position in meters of the top orbital ring.
@export var top_height: float = 3.0
## Horizontal radius in meters of the top orbital ring.
@export var top_radius: float = 4.0
## Vertical position in meters of the center orbital ring.
@export var center_height: float = 0.0
## Horizontal radius in meters of the center orbital ring.
@export var center_radius: float = 5.0
## Vertical position in meters of the bottom orbital ring.
@export var bottom_height: float = -3.0
## Horizontal radius in meters of the bottom orbital ring.
@export var bottom_radius: float = 4.0
## Curvature applied between the configured orbital rings.
@export_range(0.0, 1.0) var spline_curvature: float = 0.5
## Input axis controlling horizontal orbital angle.
@export var horizontal_axis: CameramanInputAxis
## Input axis controlling vertical orbital position.
@export var vertical_axis: CameramanInputAxis
## Input axis controlling orbital radius or ring interpolation.
@export var radial_axis: CameramanInputAxis
## Target-relative offset added before evaluating the orbital point.
@export var target_offset: Vector3 = Vector3.ZERO
## Selects whether orbital offsets follow target rotation or remain world-aligned.
@export var binding_mode: CameramanTargetTracker.BindingMode = (
	CameramanTargetTracker.BindingMode.LOCK_TO_TARGET_WITH_WORLD_UP
)
## Seconds to reach about 63% of the orbital position per axis; zero snaps immediately.
@export var position_damping: Vector3 = Vector3.ZERO
## Selects the orbital axis value returned toward its center after input stops.
@export var recentering_target: RecenteringTarget = RecenteringTarget.AXIS_CENTER

var _assigned_target: Node3D
var _assigned_reference: Quaternion = Quaternion.IDENTITY
var _assigned_captured: bool = false

func _init() -> void:
	horizontal_axis = CameramanInputAxis.new()
	horizontal_axis.range = Vector2(-180.0, 180.0)
	horizontal_axis.wrap = true
	vertical_axis = CameramanInputAxis.new()
	vertical_axis.range = Vector2(-90.0, 90.0)
	radial_axis = CameramanInputAxis.new()
	radial_axis.range = Vector2(1.0, 5.0)
	radial_axis.value = radius

func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.BODY

func rebases_on_target_warp() -> bool:
	return true

func mutate_camera_state(state: CameramanCameraState, delta: float) -> void:
	var target: Node3D = follow_target
	if _assigned_target != target:
		_assigned_target = target
		_assigned_reference = Quaternion.IDENTITY
		_assigned_captured = false
	if target == null:
		return
	var reference: Quaternion
	if binding_mode == CameramanTargetTracker.BindingMode.LOCK_TO_TARGET_ON_ASSIGN:
		if not _assigned_captured:
			_assigned_reference = target.global_basis.get_rotation_quaternion()
			_assigned_captured = true
		reference = _assigned_reference
	else:
		reference = CameramanTargetTracker.get_reference_orientation(state, binding_mode, target)
	_apply_recentering(state, target, delta, reference)
	var point: Vector3 = get_camera_point()
	var desired: Vector3 = target.global_position + target_offset + reference * point
	if not vcam.previous_state_is_valid:
		state.raw_position = desired
	else:
		state.raw_position += CameramanDamper.damp_vector(desired - state.raw_position, position_damping, delta)

## Returns the orbit point after axis values, radius, and target binding are applied.
func get_camera_point() -> Vector3:
	var horizontal: float = deg_to_rad(horizontal_axis.value)
	var vertical: float = deg_to_rad(vertical_axis.value)
	var orbit_radius: float = radius
	if radial_axis != null:
		orbit_radius = radial_axis.value if radial_axis.value > 0.0 else radius
	if orbit_style == OrbitStyle.SPHERE:
		return Vector3(
			sin(horizontal) * cos(vertical) * orbit_radius,
			sin(vertical) * orbit_radius,
			cos(horizontal) * cos(vertical) * orbit_radius
		)
	var t: float = vertical_axis.get_normalized_value()
	var ring_point: Vector3
	if t <= 0.5:
		ring_point = _quadratic_ring(
			Vector3(0.0, bottom_height, bottom_radius),
			Vector3(0.0, center_height, center_radius),
			t * 2.0
		)
	else:
		ring_point = _quadratic_ring(
			Vector3(0.0, center_height, center_radius),
			Vector3(0.0, top_height, top_radius),
			(t - 0.5) * 2.0
		)
	var radial_direction: Vector3 = Vector3(sin(horizontal), 0.0, cos(horizontal))
	return Vector3(
		radial_direction.x * ring_point.z,
		ring_point.y,
		radial_direction.z * ring_point.z
	)

## Exposes horizontal, vertical, and radial axes to input controllers.
func get_input_axes() -> Array[Dictionary]:
	return [
		{"name": "horizontal", "axis": horizontal_axis, "owner": self},
		{"name": "vertical", "axis": vertical_axis, "owner": self},
		{"name": "radial", "axis": radial_axis, "owner": self}
	]

## Reconstructs orbital axis values from an externally forced camera position.
func force_camera_position(position: Vector3, _rotation: Quaternion) -> void:
	var target: Node3D = follow_target
	if target == null:
		return
	var local: Vector3 = target.global_transform.basis.inverse() * (
		position - target.global_position - target_offset
	)
	radial_axis.value = maxf(local.length(), 0.001)
	horizontal_axis.value = rad_to_deg(atan2(local.x, local.z))
	vertical_axis.value = rad_to_deg(asin(clampf(local.y / radial_axis.value, -1.0, 1.0)))

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

func on_target_object_warped(target: Node3D, _delta: Vector3) -> void:
	if target == follow_target:
		force_camera_position(vcam.global_position, Quaternion.IDENTITY)

func _apply_recentering(
	_state: CameramanCameraState,
	target: Node3D,
	delta: float,
	reference: Quaternion
) -> void:
	if recentering_target == RecenteringTarget.NONE:
		return
	var heading: Vector3 = Vector3.FORWARD
	match recentering_target:
		RecenteringTarget.PARENT_HEADING, RecenteringTarget.PARENT_FORWARD:
			var parent_node: Node3D = vcam.get_parent() as Node3D
			if parent_node != null:
				heading = parent_node.global_basis * Vector3.FORWARD
		RecenteringTarget.TRACKING_TARGET_FORWARD:
			heading = target.global_basis * Vector3.FORWARD
		RecenteringTarget.LOOK_AT_TARGET_FORWARD:
			heading = (
				look_at_target.global_basis * Vector3.FORWARD
				if look_at_target != null
				else target.global_basis * Vector3.FORWARD
			)
		_:
			heading = Vector3.FORWARD
	var local_heading: Vector3 = reference.inverse() * heading
	var desired_horizontal: float = rad_to_deg(atan2(local_heading.x, local_heading.z))
	var desired_vertical: float = rad_to_deg(asin(clampf(local_heading.y, -1.0, 1.0)))
	_recenter_axis(horizontal_axis, desired_horizontal, delta)
	_recenter_axis(vertical_axis, desired_vertical, delta)
	_recenter_axis(radial_axis, radial_axis.center, delta)

func _recenter_axis(axis: CameramanInputAxis, destination: float, delta: float) -> void:
	if axis == null or not axis.recentering_enabled:
		return
	var original_center: float = axis.center
	axis.center = destination if recentering_target != RecenteringTarget.AXIS_CENTER else original_center
	axis.do_recentering(delta, false)
	axis.center = original_center

func _quadratic_ring(a: Vector3, b: Vector3, t: float) -> Vector3:
	var control: Vector3 = a.lerp(b, 0.5)
	control.z = lerpf(control.z, maxf(a.z, b.z), spline_curvature)
	return a.lerp(control, t).lerp(control.lerp(b, t), t)
