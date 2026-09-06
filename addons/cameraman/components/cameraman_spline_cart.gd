@tool
class_name CameramanSplineCart
## Moves a Node3D along a Path3D curve each process frame.
extends Node3D

enum PositionUnits { DISTANCE, NORMALIZED, KNOT }

## Path3D whose baked curve supplies the cart transform.
@export var spline: Path3D
## Position along the path, measured in meters or normalized units by position_units.
@export var path_position: float = 0.0
## Selects distance or normalized interpretation for path_position.
@export var position_units: PositionUnits = PositionUnits.DISTANCE
## Path units advanced per process second.
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
