@tool
class_name CameramanSequencerInstruction
extends Resource

@export var camera: NodePath
@export var blend: CameramanBlendDefinition
@export var hold: float = 1.0

func _init() -> void:
	blend = CameramanBlendDefinition.new()
