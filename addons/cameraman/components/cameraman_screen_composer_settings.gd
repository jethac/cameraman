@tool
class_name CameramanScreenComposerSettings
## Resource describing screen position, dead zones, and hard composition limits.
extends Resource

## Normalized viewport position where the target should appear.
@export var screen_position: Vector2 = Vector2(0.5, 0.5)
## Enables the region where target motion does not move the camera.
@export var dead_zone_enabled: bool = false
## Normalized viewport size of the soft dead zone.
@export var dead_zone_size: Vector2 = Vector2.ONE
## Enables the outer composition limits.
@export var hard_limits_enabled: bool = false
## Normalized viewport size of the hard limits region.
@export var hard_limits_size: Vector2 = Vector2.ONE
## Normalized offset applied to the hard limits region.
@export var hard_limits_offset: Vector2 = Vector2.ZERO

## Returns the normalized offset from screen_position to the composition target.
func get_composition_offset() -> Vector2:
	return screen_position - Vector2(0.5, 0.5)
