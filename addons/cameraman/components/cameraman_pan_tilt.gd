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

func mutate_camera_state(state: CameramanCameraState, _delta: float) -> void:
	var reference: Quaternion = _get_reference_rotation()
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
