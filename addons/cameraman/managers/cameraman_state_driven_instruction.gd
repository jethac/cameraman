@tool
class_name CameramanStateDrivenInstruction
## Resource mapping an animation state to a camera and activation timing.
extends Resource

## Animation state name that activates this instruction.
@export var state_name: StringName
## NodePath to the child camera selected by this state.
@export var camera: NodePath
## Seconds the state must remain active before switching cameras.
@export var activate_after: float = 0.0
## Minimum seconds this instruction remains active after switching.
@export var min_duration: float = 0.0
