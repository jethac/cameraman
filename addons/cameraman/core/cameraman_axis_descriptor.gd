@tool
class_name CameramanAxisDescriptor
## Provides the axis descriptor runtime helper.
extends RefCounted

var axis: RefCounted
var name: String
var hint: int
var owner: Node

func _init(
	axis_value: RefCounted = null,
	name_value: String = "",
	hint_value: int = 0,
	owner_value: Node = null
) -> void:
	axis = axis_value
	name = name_value
	hint = hint_value
	owner = owner_value
