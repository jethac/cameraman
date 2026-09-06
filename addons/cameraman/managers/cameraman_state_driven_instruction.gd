@tool
class_name CameramanStateDrivenInstruction
extends Resource

@export var state_name: StringName
@export var camera: NodePath
@export var activate_after: float = 0.0
@export var min_duration: float = 0.0
