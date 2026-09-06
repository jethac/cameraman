@tool
class_name CameramanActivationEvent
extends RefCounted

var origin: Node
var outgoing: Object
var incoming: Object
var is_cut: bool
var world_up: Vector3
var delta_time: float

func _init(
	origin_value: Node = null,
	outgoing_value: Object = null,
	incoming_value: Object = null,
	cut_value: bool = false,
	up_value: Vector3 = Vector3.UP,
	delta_value: float = 0.0
) -> void:
	origin = origin_value
	outgoing = outgoing_value
	incoming = incoming_value
	is_cut = cut_value
	world_up = up_value
	delta_time = delta_value
