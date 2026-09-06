class_name CameramanSplineCart
extends Node3D

enum PositionUnits { DISTANCE, NORMALIZED, KNOT }

@export var spline: Path3D
@export var path_position: float = 0.0
@export var position_units: PositionUnits = PositionUnits.DISTANCE
@export var speed: float = 0.0

func _process(delta: float) -> void:
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
