class_name CameramanFreeLookModifier
extends CameramanExtension

class Modifier extends Resource:
	@export var top_value: float = 0.0
	@export var bottom_value: float = 0.0

	func value_at(normalized_vertical: float) -> float:
		return lerpf(bottom_value, top_value, clampf(normalized_vertical, 0.0, 1.0))

class LensModifier extends Modifier:
	var kind: int = 0

class NoiseModifier extends Modifier:
	var kind: int = 1

class PositionDampingModifier extends Modifier:
	var kind: int = 2

class ScreenPositionModifier extends Modifier:
	var kind: int = 3

class TiltModifier extends Modifier:
	var kind: int = 4

class CompositionModifier extends Modifier:
	var kind: int = 5

@export var modifiers: Array[CameramanFreeLookModifierEntry] = []
@export var modifier_resources: Array[Modifier] = []

func pre_pipeline_mutate_camera_state(
	camera: Node,
	state: CameramanCameraState,
	_delta: float
) -> void:
	var vertical: float = 0.5
	for child in camera.get_children():
		var orbital: CameramanOrbitalFollow = child as CameramanOrbitalFollow
		if orbital != null and orbital.vertical_axis != null:
			vertical = orbital.vertical_axis.get_normalized_value()
			break
	for modifier in modifiers:
		if modifier == null:
			continue
		var value: float = modifier.value_at(vertical)
		match modifier.kind:
			CameramanFreeLookModifierEntry.Kind.LENS:
				state.lens.fov_degrees = maxf(state.lens.fov_degrees + value, 0.01)
			CameramanFreeLookModifierEntry.Kind.TILT:
				state.raw_orientation = (
					state.raw_orientation * Quaternion(Vector3.RIGHT, deg_to_rad(value))
				).normalized()
			CameramanFreeLookModifierEntry.Kind.SCREEN_POSITION:
				state.lens.frustum_offset.x += value
	for modifier_resource in modifier_resources:
		if modifier_resource == null:
			continue
		var resource_value: float = modifier_resource.value_at(vertical)
		if modifier_resource is LensModifier:
			state.lens.fov_degrees = maxf(state.lens.fov_degrees + resource_value, 0.01)
		elif modifier_resource is TiltModifier:
			state.raw_orientation = (
				state.raw_orientation * Quaternion(Vector3.RIGHT, deg_to_rad(resource_value))
			).normalized()
		elif modifier_resource is ScreenPositionModifier:
			state.lens.frustum_offset.x += resource_value
