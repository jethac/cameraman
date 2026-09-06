class_name CameramanFreeLookModifierEntry
extends Resource

enum Kind { LENS, NOISE, POSITION_DAMPING, SCREEN_POSITION, TILT, COMPOSITION }

@export var kind: Kind = Kind.LENS
@export var top_value: float = 0.0
@export var bottom_value: float = 0.0

func value_at(normalized_vertical: float) -> float:
	return lerpf(bottom_value, top_value, clampf(normalized_vertical, 0.0, 1.0))
