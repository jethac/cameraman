class_name CameramanInputAxisControl
extends Resource

enum MouseMotionAxis { NONE, X, Y }

@export var enabled: bool = true
@export var axis_name: StringName
@export var input_action_negative: StringName
@export var input_action_positive: StringName
@export var mouse_motion_axis: MouseMotionAxis = MouseMotionAxis.NONE
@export var gain: float = 1.0
@export var mouse_gain: float = 0.2
@export var accel_time: float = 0.0
@export var decel_time: float = 0.0
@export var cancel_delta_time: float = 0.0
@export var invert: bool = false

var axis: CameramanInputAxis
var owner: Node
var driver: CameramanInputAxisDriver = CameramanInputAxisDriver.new()

func read_action() -> float:
	var result: float = 0.0
	if InputMap.has_action(input_action_negative):
		result -= Input.get_action_strength(input_action_negative)
	if InputMap.has_action(input_action_positive):
		result += Input.get_action_strength(input_action_positive)
	if invert:
		result = -result
	return result * gain
