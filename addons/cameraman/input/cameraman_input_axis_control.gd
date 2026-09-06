@tool
class_name CameramanInputAxisControl
## Provides the input axis control configuration resource.
## Key properties include `enabled`, `axis_name`, `input_action_negative`, and related settings, which configure its
## behavior.
extends Resource

enum MouseMotionAxis { NONE, X, Y }

## Enables or disables enabled.
@export var enabled: bool = true
## Configures the axis name used by this type.
@export var axis_name: StringName
## Configures the input action negative used by this type.
@export var input_action_negative: StringName
## Configures the input action positive used by this type.
@export var input_action_positive: StringName
## Configures the mouse motion axis used by this type.
@export var mouse_motion_axis: MouseMotionAxis = MouseMotionAxis.NONE
## Configures the gain used by this type.
@export var gain: float = 1.0
## Configures the mouse gain used by this type.
@export var mouse_gain: float = 0.2
## Configures the accel time used by this type.
@export var accel_time: float = 0.0
## Configures the decel time used by this type.
@export var decel_time: float = 0.0
## Configures the cancel delta time used by this type.
@export var cancel_delta_time: float = 0.0
## Configures the invert used by this type.
@export var invert: bool = false

var axis: CameramanInputAxis
var owner: Node
var driver: CameramanInputAxisDriver = CameramanInputAxisDriver.new()

## Reads the configured input action value.
func read_action() -> float:
	var result: float = 0.0
	if InputMap.has_action(input_action_negative):
		result -= Input.get_action_strength(input_action_negative)
	if InputMap.has_action(input_action_positive):
		result += Input.get_action_strength(input_action_positive)
	if invert:
		result = -result
	return result * gain
