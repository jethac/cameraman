@tool
class_name CameramanRotateWithFollowTarget
## Provides the rotate with follow target camera pipeline component.
## Key properties include `damping`, which configure its behavior.
extends CameramanComponent

## Controls the damping applied to damping.
@export var damping: float = 0.0

## Returns the pipeline stage handled by this type.
func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.AIM

## Applies this component's camera-state mutation for the current pipeline step.
func mutate_camera_state(state: CameramanCameraState, delta: float) -> void:
	if follow_target == null:
		return
	var target_rotation: Quaternion = follow_target.global_basis.get_rotation_quaternion()
	if not vcam.previous_state_is_valid:
		state.raw_orientation = target_rotation
		return
	state.raw_orientation = state.raw_orientation.slerp(
		target_rotation,
		CameramanDamper.damp(1.0, damping, delta)
	)

## Handles the transition from camera event.
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

## Forces the camera and its pipeline state to a position and rotation.
func force_camera_position(_position: Vector3, rotation: Quaternion) -> void:
	if vcam != null:
		vcam.call("set_meta", "cameraman_rotate_follow_rotation", rotation)
