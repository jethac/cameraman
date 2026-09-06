@tool
class_name CameramanBlendDefinition
## Describes transition style, duration, and curve settings used when blending camera states.
## Key properties include `style`, `time`, `custom_curve`, which configure its behavior.
extends Resource

enum Style { CUT, EASE_IN_OUT, EASE_IN, EASE_OUT, HARD_IN, HARD_OUT, LINEAR, CUSTOM }

## Configures the style used by this type.
@export var style: Style:
	get:
		return _style
	set(value):
		_style = value
		_cached_curve = null

## Configures the time used by this type.
@export var time: float = 2.0
## Configures the custom curve used by this type.
@export var custom_curve: Curve:
	get:
		return _custom_curve
	set(value):
		_custom_curve = value
		_cached_curve = null

var _style: Style = Style.EASE_IN_OUT
var _custom_curve: Curve
var _cached_curve: Curve

## Returns the duration of this blend.
func blend_time() -> float:
	return 0.0 if style == Style.CUT else maxf(time, 0.0)

## Returns the curve.
func get_curve() -> Curve:
	if _cached_curve != null:
		return _cached_curve
	_cached_curve = Curve.new()
	if style == Style.CUSTOM and custom_curve != null:
		_cached_curve = custom_curve
		return _cached_curve
	_cached_curve.min_value = 0.0
	_cached_curve.max_value = 1.0
	_cached_curve.add_point(Vector2(0.0, 0.0))
	_cached_curve.add_point(Vector2(1.0, 1.0))
	match style:
		Style.CUT:
			_cached_curve.clear_points()
			_cached_curve.add_point(Vector2(0.0, 1.0))
		Style.EASE_IN_OUT:
			_cached_curve.set_point_left_tangent(0, 0.0)
			_cached_curve.set_point_right_tangent(0, 0.0)
			_cached_curve.set_point_left_tangent(1, 0.0)
			_cached_curve.set_point_right_tangent(1, 0.0)
		Style.EASE_IN:
			_cached_curve.set_point_right_tangent(0, 0.0)
			_cached_curve.set_point_left_tangent(1, 2.0)
		Style.EASE_OUT:
			_cached_curve.set_point_right_tangent(0, 0.5)
			_cached_curve.set_point_left_tangent(1, 0.0)
		Style.HARD_IN:
			_cached_curve.set_point_right_tangent(0, 0.0)
			_cached_curve.set_point_left_tangent(1, 1.0)
		Style.HARD_OUT:
			_cached_curve.set_point_right_tangent(0, 1.0)
			_cached_curve.set_point_left_tangent(1, 0.0)
		Style.LINEAR:
			_cached_curve.set_point_right_tangent(0, 1.0)
			_cached_curve.set_point_left_tangent(1, 1.0)
	return _cached_curve
