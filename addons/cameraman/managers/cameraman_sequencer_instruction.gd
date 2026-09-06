@tool
class_name CameramanSequencerInstruction
## Provides the sequencer instruction configuration resource.
## Key properties include `camera`, `blend`, `hold`, which configure its behavior.
extends Resource

## Configures the camera used by this type.
@export var camera: NodePath
## Defines the blend behavior used by blend.
@export var blend: CameramanBlendDefinition
## Configures the hold used by this type.
@export var hold: float = 1.0

func _init() -> void:
	blend = CameramanBlendDefinition.new()
