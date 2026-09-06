@tool
class_name CameramanRotationComposer
## Aims the camera toward its target while placing it at the configured screen composition.
## Key properties include `target_offset`, `lookahead_enabled`, `lookahead_time`, and related settings, which
## configure its behavior.
extends CameramanComponent

## Specifies the target used by target offset.
@export var target_offset: Vector3 = Vector3.ZERO
## Configures the lookahead enabled used by this type.
@export var lookahead_enabled: bool = false
## Configures the lookahead time used by this type.
@export var lookahead_time: float = 0.0
## Configures the lookahead smoothing used by this type.
@export var lookahead_smoothing: float = 0.0
## Controls the damping applied to damping.
@export var damping: Vector2 = Vector2.ZERO
## Configures the composition used by this type.
@export var composition: CameramanScreenComposerSettings
## Configures the center on activate used by this type.
@export var center_on_activate: bool = false
var _lookahead: CameramanLookahead = CameramanLookahead.new()

func _init() -> void:
	composition = CameramanScreenComposerSettings.new()

## Returns the pipeline stage handled by this type.
func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.AIM

## Applies this component's camera-state mutation for the current pipeline step.
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
