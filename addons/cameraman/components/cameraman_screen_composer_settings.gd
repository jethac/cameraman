@tool
class_name CameramanScreenComposerSettings
extends Resource

@export var screen_position: Vector2 = Vector2(0.5, 0.5)
@export var dead_zone_enabled: bool = false
@export var dead_zone_size: Vector2 = Vector2.ONE
@export var hard_limits_enabled: bool = false
@export var hard_limits_size: Vector2 = Vector2.ONE
@export var hard_limits_offset: Vector2 = Vector2.ZERO

func get_composition_offset() -> Vector2:
	return screen_position - Vector2(0.5, 0.5)
