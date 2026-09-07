@tool
class_name CameramanPositionComposer
## BODY-stage component that moves the camera to keep its target inside a screen-space dead zone.
extends CameramanComponent

## Point offset from the target used for screen-space positioning.
@export var target_offset: Vector3 = Vector3.ZERO
## Projects the target from predicted motion before applying composition.
@export var lookahead_enabled: bool = false
## Prediction horizon in seconds for position composition.
@export var lookahead_time: float = 0.0
## Damping in seconds applied to predicted target motion.
@export var lookahead_smoothing: float = 0.0
## Ignores vertical target velocity when projecting lookahead.
@export var lookahead_ignore_y: bool = false
## Distance in meters maintained along the camera forward direction.
@export var camera_distance: float = 0.0
## Depth in meters used to keep the target inside the dead-zone volume.
@export var dead_zone_depth: float = 0.0
## Seconds to reach about 63% of the desired camera position; zero snaps immediately.
@export var damping: Vector3 = Vector3.ZERO
## Screen position and dead-zone settings used to compute the camera correction.
@export var composition: CameramanScreenComposerSettings
## Allows soft-zone correction without a hard limit on lateral travel.
@export var unlimited_soft_zone: bool = false
## Centers the target on the first valid frame after activation.
@export var center_on_activate: bool = false
## Applies composition only when target motion changes the projected error.
@export var target_movement_only: bool = false

var _lookahead: CameramanLookahead = CameramanLookahead.new()

func _init() -> void:
	composition = CameramanScreenComposerSettings.new()

func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.BODY

func rebases_on_target_warp() -> bool:
	return true

## Returns true so position correction can run after AIM components.
func body_applies_after_aim() -> bool:
	return true

func mutate_camera_state(state: CameramanCameraState, delta: float) -> void:
	var target: Node3D = look_at_target if look_at_target != null else follow_target
	if target == null:
		return
	var target_position: Vector3 = target.global_position + target_offset
	if lookahead_enabled:
		_lookahead.record(target.global_position, CameramanCore.current_time())
		var predicted: Vector3 = _lookahead.predict(lookahead_time, lookahead_ignore_y)
		var lookahead_weight: float = CameramanDamper.damp(1.0, lookahead_smoothing, delta)
		target_position = target.global_position.lerp(predicted, lookahead_weight) + target_offset
	var forward: Vector3 = state.raw_orientation * Vector3.FORWARD
	var desired: Vector3 = target_position - forward * camera_distance
	if camera_distance > 0.0 and not vcam.previous_state_is_valid:
		state.raw_position = desired
	var correction: Vector3 = CameramanComposerMath.move_to_composition(
		state.get_final_position(),
		state.raw_orientation,
		target_position,
		state.lens,
		composition,
		delta,
		damping
	)
	if composition.dead_zone_enabled or not unlimited_soft_zone:
		state.raw_position -= correction
	if dead_zone_depth > 0.0:
		var depth: float = -(
			state.raw_orientation.inverse() * (target_position - state.get_final_position())
		).z
		if depth < dead_zone_depth:
			state.raw_position -= forward * (dead_zone_depth - depth)

## Updates camera distance and composition state from an externally forced position.
func force_camera_position(position: Vector3, _rotation: Quaternion) -> void:
	if vcam != null:
		vcam.call("set_meta", "cameraman_position_composer_position", position)

func on_target_object_warped(target: Node3D, delta: Vector3) -> void:
	var tracked_target: Node3D = look_at_target if look_at_target != null else follow_target
	if target == tracked_target:
		_lookahead.offset_history(delta)

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
