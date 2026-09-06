class_name CameramanSequencerCamera
extends CameramanCameraManagerBase

@export var instructions: Array[CameramanSequencerInstruction] = []
@export var loop: bool = true

var time_in_sequence: float = 0.0
var _instruction_index: int = 0

func on_camera_activated(event: CameramanActivationEvent) -> void:
	reset_sequence()
	super.on_camera_activated(event)

func choose_current_camera(_world_up: Vector3, delta: float) -> CameramanVirtualCameraBase:
	if instructions.is_empty():
		return super.choose_current_camera(_world_up, delta)
	time_in_sequence += maxf(delta, 0.0)
	while _instruction_index < instructions.size():
		var current: CameramanSequencerInstruction = instructions[_instruction_index]
		if time_in_sequence < maxf(current.hold, 0.0):
			return get_node_or_null(current.camera) as CameramanVirtualCameraBase
		time_in_sequence -= maxf(current.hold, 0.0)
		_instruction_index += 1
	if loop:
		reset_sequence()
		return choose_current_camera(_world_up, 0.0)
	return get_node_or_null(instructions.back().camera) as CameramanVirtualCameraBase

func get_blend_definition(
	from_source: Object,
	to_source: Object,
	fallback: CameramanBlendDefinition
) -> CameramanBlendDefinition:
	if _instruction_index >= 0 and _instruction_index < instructions.size():
		var definition: CameramanBlendDefinition = instructions[_instruction_index].blend
		if definition != null:
			return definition
	return super.get_blend_definition(from_source, to_source, fallback)

func reset_sequence() -> void:
	time_in_sequence = 0.0
	_instruction_index = 0
