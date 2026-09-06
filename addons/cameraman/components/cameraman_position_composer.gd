class_name CameramanPositionComposer
extends CameramanComponent

@export var target_offset: Vector3 = Vector3.ZERO
@export var lookahead_enabled: bool = false
@export var lookahead_time: float = 0.0
@export var lookahead_smoothing: float = 0.0
@export var lookahead_ignore_y: bool = false
@export var camera_distance: float = 0.0
@export var dead_zone_depth: float = 0.0
@export var damping: Vector3 = Vector3.ZERO
@export var composition: CameramanScreenComposerSettings
@export var unlimited_soft_zone: bool = false
@export var center_on_activate: bool = false
@export var target_movement_only: bool = false

var _lookahead: CameramanLookahead = CameramanLookahead.new()

func _init() -> void:
	composition = CameramanScreenComposerSettings.new()

func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.BODY

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
		state.raw_position,
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
			state.raw_orientation.inverse() * (target_position - state.raw_position)
		).z
		if depth < dead_zone_depth:
			state.raw_position -= forward * (dead_zone_depth - depth)

func force_camera_position(position: Vector3, _rotation: Quaternion) -> void:
	if vcam != null:
		vcam.call("set_meta", "cameraman_position_composer_position", position)
