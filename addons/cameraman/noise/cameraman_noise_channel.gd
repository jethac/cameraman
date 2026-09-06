@tool
class_name CameramanNoiseChannel
## Resource containing per-axis noise parameter sets.
extends Resource

## Noise parameters sampled for the local X axis.
@export var x: CameramanNoiseParams
## Noise parameters sampled for the local Y axis.
@export var y: CameramanNoiseParams
## Noise parameters sampled for the local Z axis.
@export var z: CameramanNoiseParams

func _init() -> void:
	x = CameramanNoiseParams.new()
	y = CameramanNoiseParams.new()
	z = CameramanNoiseParams.new()
