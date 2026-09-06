@tool
class_name CameramanBlendEvent
extends RefCounted

var origin: Node
var blend: CameramanBlend

func _init(origin_value: Node = null, blend_value: CameramanBlend = null) -> void:
	origin = origin_value
	blend = blend_value
