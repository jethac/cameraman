@tool
class_name CameramanNoiseChannel
## Provides the noise channel configuration resource.
## Key properties include `x`, `y`, `z`, which configure its behavior.
extends Resource

## Configures the x used by this type.
@export var x: CameramanNoiseParams
## Configures the y used by this type.
@export var y: CameramanNoiseParams
## Configures the z used by this type.
@export var z: CameramanNoiseParams

func _init() -> void:
	x = CameramanNoiseParams.new()
	y = CameramanNoiseParams.new()
	z = CameramanNoiseParams.new()
