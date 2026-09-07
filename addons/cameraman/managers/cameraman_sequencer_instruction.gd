@tool
class_name CameramanSequencerInstruction
## Resource describing one sequencer camera, blend, and hold duration.
extends Resource

## NodePath to the child virtual camera selected by this instruction.
@export var camera: NodePath
## Transition definition used when entering this instruction.
@export var blend: CameramanBlendDefinition
## Seconds this instruction remains selected before advancing.
@export var hold: float = 1.0

func _init() -> void:
	blend = CameramanBlendDefinition.new()
