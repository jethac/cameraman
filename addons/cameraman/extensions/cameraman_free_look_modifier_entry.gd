@tool
class_name CameramanFreeLookModifierEntry
## Resource describing one top and bottom free-look modifier value.
extends Resource

enum Kind { LENS, NOISE, POSITION_DAMPING, SCREEN_POSITION, TILT, COMPOSITION }

## Selects whether the modifier changes lens or camera position.
@export var kind: Kind = Kind.LENS
## Modifier value at the top of the free-look range.
@export var top_value: float = 0.0
## Modifier value at the bottom of the free-look range.
@export var bottom_value: float = 0.0

## Linearly interpolates between bottom_value and top_value.
func value_at(normalized_vertical: float) -> float:
	return lerpf(bottom_value, top_value, clampf(normalized_vertical, 0.0, 1.0))
