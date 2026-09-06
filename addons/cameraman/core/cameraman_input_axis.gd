@tool
class_name CameramanInputAxis
## Resource storing an input value, range, wrapping, and optional recentering policy.
extends Resource

enum RecenteringTarget { NONE, AXIS_CENTER, PARENT_HEADING, TARGET_FORWARD }
enum Restriction { NONE, RANGE_IS_DRIVEN, NO_RECENTERING, MOMENTARY }

## Current axis value, clamped or wrapped according to the resource settings.
@export var value: float = 0.0
## Value used as the recentering midpoint.
@export var center: float = 0.0
## Inclusive minimum and maximum values used by clamp and normalization.
@export var range: Vector2 = Vector2(-1.0, 1.0)
## Wraps values across the configured range instead of clamping them.
@export var wrap: bool = false
## Allows do_recentering to move the axis after the wait period.
@export var recentering_enabled: bool = false
## Seconds input must remain idle before recentering starts.
@export var recentering_wait: float = 1.0
## Seconds used to move from the current value to the recentering target.
@export var recentering_time: float = 1.0
## Selects the axis center or zero as the recentering destination.
@export var recentering_target: RecenteringTarget = RecenteringTarget.AXIS_CENTER
## Selects whether input is unrestricted, positive-only, or negative-only.
@export var restriction: Restriction = Restriction.NONE

var _recenter_elapsed: float = 0.0
var _input_changed: bool = false

## Maps value from range to normalized 0 to 1, preserving wrap behavior.
func get_normalized_value() -> float:
	var span: float = range.y - range.x
	if absf(span) < 0.000001:
		return 0.0
	return clampf((value - range.x) / span, 0.0, 1.0)

## Repairs invalid ranges and clamps the current value to the configured limits.
func validate() -> bool:
	return range.x < range.y and is_finite(center) and is_finite(value)

## Clamps or wraps new_value according to range and wrap.
func clamp_value(new_value: float) -> float:
	if wrap:
		return wrapf(new_value - range.x, 0.0, range.y - range.x) + range.x
	return clampf(new_value, range.x, range.y)

func set_value(new_value: float) -> void:
	value = clamp_value(new_value)
	_input_changed = true
	_recenter_elapsed = 0.0

## Stores an input sample and marks the axis as changed for recentering.
func track_input_value(new_value: float) -> void:
	set_value(new_value)

## Moves toward the recentering target after the idle wait period.
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

## Cancels recentering and preserves the current axis value.
func cancel_recentering() -> void:
	_recenter_elapsed = 0.0

func reset() -> void:
	value = center
	_recenter_elapsed = 0.0
	_input_changed = false

## Returns true until clear_input_changed is called after consuming the sample.
func has_input_changed() -> bool:
	return _input_changed

## Marks the current input sample as consumed.
func clear_input_changed() -> void:
	_input_changed = false
