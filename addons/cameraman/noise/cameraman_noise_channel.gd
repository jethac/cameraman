@tool
class_name CameramanNoiseChannel
extends Resource

@export var x: CameramanNoiseParams
@export var y: CameramanNoiseParams
@export var z: CameramanNoiseParams

func _init() -> void:
	x = CameramanNoiseParams.new()
	y = CameramanNoiseParams.new()
	z = CameramanNoiseParams.new()
