@tool
class_name CameramanInputAxis
## Provides the input axis configuration resource.
## Key properties include `value`, `center`, `range`, and related settings, which configure its behavior.
extends Resource

enum RecenteringTarget { NONE, AXIS_CENTER, PARENT_HEADING, TARGET_FORWARD }
enum Restriction { NONE, RANGE_IS_DRIVEN, NO_RECENTERING, MOMENTARY }

## Configures the value used by this type.
@export var value: float = 0.0
## Configures the center used by this type.
@export var center: float = 0.0
## Configures the range used by this type.
@export var range: Vector2 = Vector2(-1.0, 1.0)
## Configures the wrap used by this type.
@export var wrap: bool = false
## Configures the recentering enabled used by this type.
@export var recentering_enabled: bool = false
## Configures the recentering wait used by this type.
@export var recentering_wait: float = 1.0
## Configures the recentering time used by this type.
@export var recentering_time: float = 1.0
## Specifies the target used by recentering target.
@export var recentering_target: RecenteringTarget = RecenteringTarget.AXIS_CENTER
## Configures the restriction used by this type.
@export var restriction: Restriction = Restriction.NONE

var _recenter_elapsed: float = 0.0
var _input_changed: bool = false

## Returns the normalized value.
func get_normalized_value() -> float:
	var span: float = range.y - range.x
	if absf(span) < 0.000001:
		return 0.0
	return clampf((value - range.x) / span, 0.0, 1.0)

## Validates and normalizes this resource's settings.
func validate() -> bool:
	return range.x < range.y and is_finite(center) and is_finite(value)

## Clamps a value to the configured axis range.
func clamp_value(new_value: float) -> float:
	if wrap:
		return wrapf(new_value - range.x, 0.0, range.y - range.x) + range.x
	return clampf(new_value, range.x, range.y)

## Sets the value.
func set_value(new_value: float) -> void:
	value = clamp_value(new_value)
	_input_changed = true
	_recenter_elapsed = 0.0

## Tracks the input value.
func track_input_value(new_value: float) -> void:
	set_value(new_value)

## Applies recentering over the supplied time step.
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

## Cancels any active recentering.
func cancel_recentering() -> void:
	_recenter_elapsed = 0.0

## Resets the stored state.
func reset() -> void:
	value = center
	_recenter_elapsed = 0.0
	_input_changed = false

## Returns whether the input value changed.
func has_input_changed() -> bool:
	return _input_changed

## Clears the input-changed flag.
func clear_input_changed() -> void:
	_input_changed = false
