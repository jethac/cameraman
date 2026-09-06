@tool
class_name CameramanRotationComposer
## AIM-stage component that aims toward the target while applying screen-space composition.
extends CameramanComponent

## Point offset from the target used when computing look direction.
@export var target_offset: Vector3 = Vector3.ZERO
## Aims at predicted target motion instead of only the current target point.
@export var lookahead_enabled: bool = false
## Prediction horizon in seconds for aiming ahead of the target.
@export var lookahead_time: float = 0.0
## Damping in seconds applied to lookahead target motion.
@export var lookahead_smoothing: float = 0.0
## Seconds to reach about 63% of desired orientation per axis; zero snaps immediately.
@export var damping: Vector2 = Vector2.ZERO
## Screen-space target placement used to derive the desired orientation.
@export var composition: CameramanScreenComposerSettings
## Temporarily centers the target on the first valid frame after activation.
@export var center_on_activate: bool = false
var _lookahead: CameramanLookahead = CameramanLookahead.new()

func _init() -> void:
	composition = CameramanScreenComposerSettings.new()

func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.AIM

## Computes orientation from corrected position and composition, with a safe behind-camera
## fallback.
func mutate_camera_state(state: CameramanCameraState, delta: float) -> void:
	if not state.has_look_at():
		return
	var target: Vector3 = state.reference_look_at + target_offset
	if lookahead_enabled and look_at_target != null:
		_lookahead.record(look_at_target.global_position, CameramanCore.current_time())
		target = _lookahead.predict(lookahead_time, false) + target_offset
	state.raw_orientation = CameramanComposerMath.rotate_to_composition(
		state.get_final_position(),
		state.raw_orientation,
		target,
		state.lens,
		composition,
		delta,
		damping
	)
