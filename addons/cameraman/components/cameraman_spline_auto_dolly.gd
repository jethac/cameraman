class_name CameramanSplineAutoDolly
extends Resource

enum Mode { FIXED_SPEED, NEAREST_POINT_TO_TARGET }

@export var enabled: bool = false
@export var mode: Mode = Mode.FIXED_SPEED
@export var speed: float = 1.0
@export var position_offset: float = 0.0
