@tool
class_name CameramanShot
## Provides the shot scene node.
## Key properties include `camera`, `weight`, `active`, which configure its behavior.
extends Node

## Configures the camera used by this type.
@export var camera: NodePath
## Configures the weight used by this type.
@export_range(0.0, 1.0) var weight: float = 0.0
## Enables or disables active.
@export var active: bool = true
