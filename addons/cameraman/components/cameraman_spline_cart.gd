@tool
class_name CameramanSplineCart
## Provides the spline cart scene node.
## Key properties include `spline`, `path_position`, `position_units`, and related settings, which configure its
## behavior.
extends Node3D

enum PositionUnits { DISTANCE, NORMALIZED, KNOT }

## Configures the spline used by this type.
@export var spline: Path3D
## Configures the path position used by this type.
@export var path_position: float = 0.0
## Configures the position units used by this type.
@export var position_units: PositionUnits = PositionUnits.DISTANCE
## Configures the speed used by this type.
@export var speed: float = 0.0

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if spline == null or spline.curve == null:
		return
	path_position += speed * delta
	var length: float = spline.curve.get_baked_length()
	var distance: float = (
		path_position * length
		if position_units == PositionUnits.NORMALIZED
		else path_position
	)
	var sample: Transform3D = spline.curve.sample_baked_with_rotation(distance, true, true)
	global_transform = spline.global_transform * sample
