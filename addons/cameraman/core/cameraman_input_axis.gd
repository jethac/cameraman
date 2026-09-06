class_name CameramanInputAxis
extends Resource

enum RecenteringTarget { NONE, AXIS_CENTER, PARENT_HEADING, TARGET_FORWARD }
enum Restriction { NONE, RANGE_IS_DRIVEN, NO_RECENTERING, MOMENTARY }

@export var value: float = 0.0
@export var center: float = 0.0
@export var range: Vector2 = Vector2(-1.0, 1.0)
@export var wrap: bool = false
@export var recentering_enabled: bool = false
@export var recentering_wait: float = 1.0
@export var recentering_time: float = 1.0
@export var recentering_target: RecenteringTarget = RecenteringTarget.AXIS_CENTER
@export var restriction: Restriction = Restriction.NONE

var _recenter_elapsed: float = 0.0
var _input_changed: bool = false

func get_normalized_value() -> float:
	var span: float = range.y - range.x
	if absf(span) < 0.000001:
		return 0.0
	return clampf((value - range.x) / span, 0.0, 1.0)

func validate() -> bool:
	return range.x < range.y and is_finite(center) and is_finite(value)

func clamp_value(new_value: float) -> float:
	if wrap:
		return wrapf(new_value - range.x, 0.0, range.y - range.x) + range.x
	return clampf(new_value, range.x, range.y)

func set_value(new_value: float) -> void:
	value = clamp_value(new_value)
	_input_changed = true
	_recenter_elapsed = 0.0

func track_input_value(new_value: float) -> void:
	set_value(new_value)

func do_recentering(delta: float, force: bool = false) -> void:
	if not recentering_enabled or restriction == Restriction.NO_RECENTERING:
		return
	if not force:
		_recenter_elapsed += maxf(delta, 0.0)
		if _recenter_elapsed < recentering_wait:
			return
	var duration: float = maxf(recentering_time, 0.0001)
	value = lerpf(value, center, CameramanDamper.damp(1.0, duration, delta))
	if absf(value - center) < 0.0001:
		value = center

func cancel_recentering() -> void:
	_recenter_elapsed = 0.0

func reset() -> void:
	value = center
	_recenter_elapsed = 0.0
	_input_changed = false

func has_input_changed() -> bool:
	return _input_changed

func clear_input_changed() -> void:
	_input_changed = false
