@tool
class_name CameramanSplineAutoDolly
## Provides the spline auto dolly configuration resource.
## Key properties include `enabled`, `mode`, `speed`, and related settings, which configure its behavior.
extends Resource

enum Mode { FIXED_SPEED, NEAREST_POINT_TO_TARGET }

## Enables or disables enabled.
@export var enabled: bool = false
## Selects the mode behavior.
@export var mode: Mode = Mode.FIXED_SPEED
## Configures the speed used by this type.
@export var speed: float = 1.0
## Configures the position offset used by this type.
@export var position_offset: float = 0.0
