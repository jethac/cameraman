class_name CameramanOrbitalFollow
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

@export var orbit_style: OrbitStyle = OrbitStyle.SPHERE
@export var radius: float = 5.0
@export var top_height: float = 3.0
@export var top_radius: float = 4.0
@export var center_height: float = 0.0
@export var center_radius: float = 5.0
@export var bottom_height: float = -3.0
@export var bottom_radius: float = 4.0
@export_range(0.0, 1.0) var spline_curvature: float = 0.5
@export var horizontal_axis: CameramanInputAxis
@export var vertical_axis: CameramanInputAxis
@export var radial_axis: CameramanInputAxis
@export var target_offset: Vector3 = Vector3.ZERO
@export var binding_mode: CameramanTargetTracker.BindingMode = (
	CameramanTargetTracker.BindingMode.LOCK_TO_TARGET_WITH_WORLD_UP
)
@export var position_damping: Vector3 = Vector3.ZERO
@export var recentering_target: RecenteringTarget = RecenteringTarget.AXIS_CENTER

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

func mutate_camera_state(state: CameramanCameraState, delta: float) -> void:
	var target: Node3D = follow_target
	if target == null:
		return
	var reference: Quaternion = CameramanTargetTracker.get_reference_orientation(
		state,
		binding_mode,
		target
	)
	var point: Vector3 = get_camera_point()
	var desired: Vector3 = target.global_position + target_offset + reference * point
	if not vcam.previous_state_is_valid:
		state.raw_position = desired
	else:
		state.raw_position += CameramanDamper.damp_vector(desired - state.raw_position, position_damping, delta)

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
			Vector3(0.0, top_height, top_radius),
			Vector3(0.0, center_height, center_radius),
			t * 2.0
		)
	else:
		ring_point = _quadratic_ring(
			Vector3(0.0, center_height, center_radius),
			Vector3(0.0, bottom_height, bottom_radius),
			(t - 0.5) * 2.0
		)
	var radial_direction: Vector3 = Vector3(sin(horizontal), 0.0, cos(horizontal))
	return Vector3(
		radial_direction.x * ring_point.z,
		ring_point.y,
		radial_direction.z * ring_point.z
	)

func get_input_axes() -> Array[Dictionary]:
	return [
		{"name": "horizontal", "axis": horizontal_axis, "owner": self},
		{"name": "vertical", "axis": vertical_axis, "owner": self},
		{"name": "radial", "axis": radial_axis, "owner": self}
	]

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
	if from == null or not from.has_method("get_state"):
		return false
	var previous: CameramanCameraState = from.get_state()
	force_camera_position(previous.get_final_position(), previous.get_final_orientation())
	return true

func on_target_object_warped(target: Node3D, delta: Vector3) -> void:
	if target == follow_target:
		var camera_position: Vector3 = vcam.call("get_state").get_final_position()
		force_camera_position(camera_position + delta, Quaternion.IDENTITY)

func _quadratic_ring(a: Vector3, b: Vector3, t: float) -> Vector3:
	var control: Vector3 = a.lerp(b, 0.5)
	control.z = lerpf(control.z, maxf(a.z, b.z), spline_curvature)
	return a.lerp(control, t).lerp(control.lerp(b, t), t)
