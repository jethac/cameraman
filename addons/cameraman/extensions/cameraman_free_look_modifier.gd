@tool
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
var _restores: Array[Dictionary] = []

func pre_pipeline_mutate_camera_state(
	camera: Node,
	state: CameramanCameraState,
	_delta: float
) -> void:
	_restores.clear()
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
		elif modifier_resource is NoiseModifier:
			for child in camera.get_children():
				var noise: CameramanBasicMultiChannelPerlin = child as CameramanBasicMultiChannelPerlin
				if noise == null:
					continue
				_save_and_set(noise, &"amplitude_gain", noise.amplitude_gain * resource_value)
				_save_and_set(noise, &"frequency_gain", noise.frequency_gain * resource_value)
		elif modifier_resource is PositionDampingModifier:
			for child in camera.get_children():
				var orbital: CameramanOrbitalFollow = child as CameramanOrbitalFollow
				if orbital == null:
					continue
				_save_and_set(orbital, &"position_damping", orbital.position_damping * resource_value)
		elif modifier_resource is TiltModifier:
			state.raw_orientation = (
				state.raw_orientation * Quaternion(Vector3.RIGHT, deg_to_rad(resource_value))
			).normalized()
		elif modifier_resource is ScreenPositionModifier:
			state.lens.frustum_offset.x += resource_value
		elif modifier_resource is CompositionModifier:
			for child in camera.get_children():
				var composer: CameramanPositionComposer = child as CameramanPositionComposer
				if composer != null:
					_save_and_set(
						composer.composition,
						&"dead_zone_size",
						composer.composition.dead_zone_size * resource_value
					)
				var rotation_composer: CameramanRotationComposer = child as CameramanRotationComposer
				if rotation_composer != null:
					_save_and_set(
						rotation_composer.composition,
						&"dead_zone_size",
						rotation_composer.composition.dead_zone_size * resource_value
					)

func post_pipeline_stage_callback(
	_camera: Node,
	stage: CameramanCore.Stage,
	_state: CameramanCameraState,
	_delta: float
) -> void:
	if stage != CameramanCore.Stage.FINALIZE:
		return
	for restore in _restores:
		restore.object.set(restore.property, restore.value)
	_restores.clear()

func _save_and_set(object: Object, property: StringName, value: Variant) -> void:
	_restores.append({"object": object, "property": property, "value": object.get(property)})
	object.set(property, value)
