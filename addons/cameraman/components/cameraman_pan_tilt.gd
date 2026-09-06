class_name CameramanPanTilt
extends CameramanComponent

enum ReferenceFrame { PARENT_OBJECT, TRACKING_TARGET, LOOK_AT_TARGET, WORLD }
enum RecenteringTarget { NONE, AXIS_CENTER, PARENT_HEADING, TARGET_FORWARD }

@export var pan_axis: CameramanInputAxis
@export var tilt_axis: CameramanInputAxis
@export var reference_frame: ReferenceFrame = ReferenceFrame.PARENT_OBJECT
@export var recentering_target: RecenteringTarget = RecenteringTarget.AXIS_CENTER

func _init() -> void:
	pan_axis = CameramanInputAxis.new()
	pan_axis.range = Vector2(-180.0, 180.0)
	pan_axis.wrap = true
	tilt_axis = CameramanInputAxis.new()
	tilt_axis.range = Vector2(-70.0, 70.0)

func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.AIM

func mutate_camera_state(state: CameramanCameraState, delta: float) -> void:
	var reference: Quaternion = _get_reference_rotation()
	_apply_recentering(reference, delta)
	var local_rotation: Quaternion = Quaternion.from_euler(Vector3(
		deg_to_rad(tilt_axis.value),
		deg_to_rad(pan_axis.value),
		0.0
	))
	state.raw_orientation = (reference * local_rotation).normalized()

func get_input_axes() -> Array[Dictionary]:
	return [
		{"name": "pan", "axis": pan_axis, "owner": self},
		{"name": "tilt", "axis": tilt_axis, "owner": self}
	]

func _get_reference_rotation() -> Quaternion:
	match reference_frame:
		ReferenceFrame.TRACKING_TARGET:
			return follow_target_rotation
		ReferenceFrame.LOOK_AT_TARGET:
			return (
				look_at_target.global_basis.get_rotation_quaternion()
				if look_at_target != null
				else Quaternion.IDENTITY
			)
		ReferenceFrame.WORLD:
			return Quaternion.IDENTITY
	return vcam.global_basis.get_rotation_quaternion() if vcam != null else Quaternion.IDENTITY

func _apply_recentering(reference: Quaternion, delta: float) -> void:
	if recentering_target == RecenteringTarget.NONE:
		return
	var heading: Vector3 = Vector3.FORWARD
	match recentering_target:
		RecenteringTarget.PARENT_HEADING:
			var parent_node: Node3D = vcam.get_parent() as Node3D
			if parent_node != null:
				heading = parent_node.global_basis * Vector3.FORWARD
		RecenteringTarget.TARGET_FORWARD:
			heading = (
				follow_target.global_basis * Vector3.FORWARD
				if follow_target != null
				else Vector3.FORWARD
			)
	var local_heading: Vector3 = reference.inverse() * heading
	var pan: float = rad_to_deg(atan2(local_heading.x, local_heading.z))
	var tilt: float = rad_to_deg(asin(clampf(local_heading.y, -1.0, 1.0)))
	_recenter_axis(pan_axis, pan, delta)
	_recenter_axis(tilt_axis, tilt, delta)

func _recenter_axis(axis: CameramanInputAxis, destination: float, delta: float) -> void:
	if axis == null or not axis.recentering_enabled:
		return
	var original_center: float = axis.center
	axis.center = destination if recentering_target != RecenteringTarget.AXIS_CENTER else original_center
	axis.do_recentering(delta, false)
	axis.center = original_center
