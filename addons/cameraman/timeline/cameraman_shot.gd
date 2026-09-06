@tool
class_name CameramanShot
## Scene node representing one weighted camera shot in a shot sequence.
extends Node

## NodePath to the camera driven by this shot.
@export var camera: NodePath
## Blend weight in the 0 to 1 range contributed to the sequence override.
@export_range(0.0, 1.0) var weight: float = 0.0
## Excludes this shot from sequence evaluation when disabled.
@export var active: bool = true
