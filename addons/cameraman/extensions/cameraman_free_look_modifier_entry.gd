@tool
class_name CameramanFreeLookModifierEntry
## Provides the free look modifier entry configuration resource.
## Key properties include `kind`, `top_value`, `bottom_value`, which configure its behavior.
extends Resource

enum Kind { LENS, NOISE, POSITION_DAMPING, SCREEN_POSITION, TILT, COMPOSITION }

## Configures the kind used by this type.
@export var kind: Kind = Kind.LENS
## Configures the top value used by this type.
@export var top_value: float = 0.0
## Configures the bottom value used by this type.
@export var bottom_value: float = 0.0

## Returns the modifier value at the supplied vertical position.
func value_at(normalized_vertical: float) -> float:
	return lerpf(bottom_value, top_value, clampf(normalized_vertical, 0.0, 1.0))
