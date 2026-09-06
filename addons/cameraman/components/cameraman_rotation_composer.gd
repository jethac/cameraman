class_name CameramanRotationComposer
extends CameramanComponent

@export var target_offset: Vector3 = Vector3.ZERO
@export var lookahead_enabled: bool = false
@export var lookahead_time: float = 0.0
@export var lookahead_smoothing: float = 0.0
@export var damping: Vector2 = Vector2.ZERO
@export var composition: CameramanScreenComposerSettings
@export var center_on_activate: bool = false

func _init() -> void:
	composition = CameramanScreenComposerSettings.new()

func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.AIM

func mutate_camera_state(state: CameramanCameraState, delta: float) -> void:
	if not state.has_look_at():
		return
	var target: Vector3 = state.reference_look_at + target_offset
	state.raw_orientation = CameramanComposerMath.rotate_to_composition(
		state.raw_position,
		state.raw_orientation,
		target,
		state.lens,
		composition,
		delta,
		damping
	)
