@tool
class_name CameramanObstacleAvoidance
## Stores obstacle-collision settings used to keep a camera path clear of geometry.
## Key properties include `enabled`, `collision_mask`, `camera_radius`, and related settings, which configure its
## behavior.
extends Resource

## Enables or disables enabled.
@export var enabled: bool = false
## Selects the physics layers or camera channels used by collision mask.
@export_flags_3d_physics var collision_mask: int = 1
## Sets the camera radius used by this type.
@export var camera_radius: float = 0.2
## Controls the damping applied to damping into.
@export var damping_into: float = 0.1
## Controls the damping applied to damping from collision.
@export var damping_from_collision: float = 0.2
## Specifies the target used by minimum distance from target.
@export var minimum_distance_from_target: float = 0.0
## Configures the ignore group used by this type.
@export var ignore_group: StringName
