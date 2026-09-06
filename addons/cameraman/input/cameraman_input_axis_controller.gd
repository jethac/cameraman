@tool
class_name CameramanInputAxisController
## Scene node that synchronizes axis controls and feeds input into camera components.
extends Node

## Enables input polling and axis updates for this node.
@export var enabled: bool = true
## Uses unscaled delta when updating controlled axes.
@export var ignore_time_scale: bool = false
## Finds axis controls in descendants instead of direct children only.
@export var scan_recursively: bool = false
## Prevents input changes while the containing brain is blending.
@export var suppress_input_while_blending: bool = false
## Controls mapped to the input axes discovered by this node.
@export var controls: Array[CameramanInputAxisControl] = []

var _controls: Dictionary = {}
var _mouse_motion: Vector2 = Vector2.ZERO

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	synchronize_controllers()
	call_deferred("synchronize_controllers")
	var camera: Node = get_parent()
	if camera != null:
		camera.child_entered_tree.connect(_on_camera_child_entered_tree)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not enabled:
		return
	var step: float = delta
	if ignore_time_scale and Engine.time_scale != 0.0:
		step /= Engine.time_scale
	for control in _controls.values():
		var axis_control: CameramanInputAxisControl = control as CameramanInputAxisControl
		if axis_control == null or not axis_control.enabled or axis_control.axis == null:
			continue
		var input_value: float = axis_control.read_action()
		var mouse_delta: float = 0.0
		if axis_control.mouse_motion_axis == CameramanInputAxisControl.MouseMotionAxis.X:
			mouse_delta = _mouse_motion.x * axis_control.mouse_gain
		elif axis_control.mouse_motion_axis == CameramanInputAxisControl.MouseMotionAxis.Y:
			mouse_delta = _mouse_motion.y * axis_control.mouse_gain
		if axis_control.invert:
			mouse_delta = -mouse_delta
		if not is_zero_approx(mouse_delta):
			axis_control.axis.track_input_value(axis_control.axis.value + mouse_delta)
			continue
		var driven: float = axis_control.driver.update(
			input_value,
			step,
			axis_control.accel_time,
			axis_control.decel_time
		)
		if not is_zero_approx(driven):
			axis_control.axis.track_input_value(axis_control.axis.value + driven * step)
		else:
			axis_control.axis.do_recentering(step)
	_mouse_motion = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null:
		_mouse_motion += motion.relative

func _on_camera_child_entered_tree(_child: Node) -> void:
	call_deferred("synchronize_controllers")

## Rebuilds axis bindings from controls, preserving existing axis resources when possible.
func synchronize_controllers() -> void:
	var camera: Node = get_parent()
	if camera == null:
		return
	var preserved: Dictionary = {}
	for control in controls:
		if control != null and not control.axis_name.is_empty():
			preserved[control.axis_name] = control
	for control in _controls.values():
		var existing: CameramanInputAxisControl = control as CameramanInputAxisControl
		if existing != null and not existing.axis_name.is_empty():
			preserved[existing.axis_name] = existing
	var synchronized: Array[CameramanInputAxisControl] = []
	var next_controls: Dictionary = {}
	var children: Array[Node] = camera.get_children()
	for child in children:
		var component: CameramanComponent = child as CameramanComponent
		if component == null:
			continue
		var descriptors: Array[Dictionary] = component.get_input_axes()
		for descriptor in descriptors:
			var axis: CameramanInputAxis = descriptor.get("axis") as CameramanInputAxis
			var name_value: String = str(descriptor.get("name", ""))
			if axis == null or name_value.is_empty():
				continue
			var control: CameramanInputAxisControl = preserved.get(name_value) as CameramanInputAxisControl
			if control == null:
				control = CameramanInputAxisControl.new()
			control.axis_name = StringName(name_value)
			control.axis = axis
			control.owner = component
			next_controls[name_value] = control
			synchronized.append(control)
	_controls = next_controls
	controls = synchronized

## Returns the control bound to name_value, or null when no binding exists.
func get_controller(name_value: String) -> CameramanInputAxisControl:
	return _controls.get(name_value) as CameramanInputAxisControl

## Requests immediate recentering for the named axis.
func trigger_recentering(name_value: String) -> void:
	var control: CameramanInputAxisControl = get_controller(name_value)
	if control != null and control.axis != null:
		control.axis.do_recentering(0.0, true)
