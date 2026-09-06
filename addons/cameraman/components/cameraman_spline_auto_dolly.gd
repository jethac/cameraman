@tool
class_name CameramanSplineAutoDolly
## Resource describing automatic spline movement mode, speed, and target offset.
extends Resource

enum Mode { FIXED_SPEED, NEAREST_POINT_TO_TARGET }

## Enables automatic movement of a spline dolly position.
@export var enabled: bool = false
## Selects fixed-speed or nearest-target spline movement.
@export var mode: Mode = Mode.FIXED_SPEED
## Distance per second, or normalized units per second when the dolly is normalized.
@export var speed: float = 1.0
## Offset added to the automatically selected spline position.
@export var position_offset: float = 0.0
