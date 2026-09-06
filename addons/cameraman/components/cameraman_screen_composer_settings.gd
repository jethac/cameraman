@tool
class_name CameramanScreenComposerSettings
## Provides the screen composer settings configuration resource.
## Key properties include `screen_position`, `dead_zone_enabled`, `dead_zone_size`, and related settings, which
## configure its behavior.
extends Resource

## Configures the screen position used by this type.
@export var screen_position: Vector2 = Vector2(0.5, 0.5)
## Configures the dead zone enabled used by this type.
@export var dead_zone_enabled: bool = false
## Sets the dead zone size used by this type.
@export var dead_zone_size: Vector2 = Vector2.ONE
## Configures the hard limits enabled used by this type.
@export var hard_limits_enabled: bool = false
## Sets the hard limits size used by this type.
@export var hard_limits_size: Vector2 = Vector2.ONE
## Configures the hard limits offset used by this type.
@export var hard_limits_offset: Vector2 = Vector2.ZERO

## Returns the composition offset.
func get_composition_offset() -> Vector2:
	return screen_position - Vector2(0.5, 0.5)
