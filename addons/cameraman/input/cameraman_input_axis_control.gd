@tool
class_name CameramanInputAxisControl
## Resource mapping actions and mouse motion to one smoothed input axis.
extends Resource

enum MouseMotionAxis { NONE, X, Y }

## Allows this control to contribute input when enabled.
@export var enabled: bool = true
## Name of the CameramanInputAxis this control updates.
@export var axis_name: StringName
## Action whose strength subtracts from the axis value.
@export var input_action_negative: StringName
## Action whose strength adds to the axis value.
@export var input_action_positive: StringName
## Selects horizontal or vertical mouse motion input.
@export var mouse_motion_axis: MouseMotionAxis = MouseMotionAxis.NONE
## Multiplies action input before acceleration and inversion.
@export var gain: float = 1.0
## Multiplies mouse motion before acceleration and inversion.
@export var mouse_gain: float = 0.2
## Seconds to reach the requested input value.
@export var accel_time: float = 0.0
## Seconds to return toward zero after input is released.
@export var decel_time: float = 0.0
## Maximum frame delta accepted before cancelling a stale input sample.
@export var cancel_delta_time: float = 0.0
## Negates the final control value after combining input sources.
@export var invert: bool = false

var axis: CameramanInputAxis
var owner: Node
var driver: CameramanInputAxisDriver = CameramanInputAxisDriver.new()

## Combines configured actions and mouse motion into one signed control value.
func read_action() -> float:
	var result: float = 0.0
	if InputMap.has_action(input_action_negative):
		result -= Input.get_action_strength(input_action_negative)
	if InputMap.has_action(input_action_positive):
		result += Input.get_action_strength(input_action_positive)
	if invert:
		result = -result
	return result * gain
