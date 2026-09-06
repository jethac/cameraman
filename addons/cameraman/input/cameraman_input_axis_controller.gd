class_name CameramanInputAxisController
extends Node

@export var enabled: bool = true
@export var ignore_time_scale: bool = false
@export var scan_recursively: bool = false
@export var suppress_input_while_blending: bool = false

var _controls: Dictionary = {}
var _mouse_motion: Vector2 = Vector2.ZERO

func _ready() -> void:
	synchronize_controllers()

func _process(delta: float) -> void:
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
		if axis_control.mouse_motion_axis == CameramanInputAxisControl.MouseMotionAxis.X:
			input_value += _mouse_motion.x * axis_control.gain
		elif axis_control.mouse_motion_axis == CameramanInputAxisControl.MouseMotionAxis.Y:
			input_value += _mouse_motion.y * axis_control.gain
		var driven: float = axis_control.driver.update(
			input_value,
			step,
			axis_control.accel_time,
			axis_control.decel_time
		)
		axis_control.axis.track_input_value(axis_control.axis.value + driven * step)
		axis_control.axis.do_recentering(step)
	_mouse_motion = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null:
		_mouse_motion += motion.relative

func synchronize_controllers() -> void:
	_controls.clear()
	var camera: Node = get_parent()
	if camera == null:
		return
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
			var control: CameramanInputAxisControl = CameramanInputAxisControl.new()
			control.axis = axis
			control.owner = component
			_controls[name_value] = control

func get_controller(name_value: String) -> CameramanInputAxisControl:
	return _controls.get(name_value) as CameramanInputAxisControl

func trigger_recentering(name_value: String) -> void:
	var control: CameramanInputAxisControl = get_controller(name_value)
	if control != null and control.axis != null:
		control.axis.do_recentering(0.0, true)
