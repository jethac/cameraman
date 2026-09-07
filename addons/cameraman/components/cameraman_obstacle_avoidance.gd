@tool
class_name CameramanObstacleAvoidance
## Stores collision settings used by camera components to keep paths clear of geometry.
extends Resource

## Enables ray or sphere casts before the camera state is written.
@export var enabled: bool = false
## Physics layers tested by obstacle casts.
@export_flags_3d_physics var collision_mask: int = 1
## Sphere-cast radius in meters; zero uses a ray cast.
@export var camera_radius: float = 0.2
## Seconds used when moving the camera toward a newly detected collision.
@export var damping_into: float = 0.1
## Seconds used when restoring distance after a collision clears.
@export var damping_from_collision: float = 0.2
## Minimum camera distance in meters; zero still keeps a 0.05 meter safety floor.
@export var minimum_distance_from_target: float = 0.0
## Bodies in this group are skipped and do not shorten the camera path.
@export var ignore_group: StringName

func _set(property: StringName, value: Variant) -> bool:
	if property == &"ignore_tag_group_name":
		ignore_group = value
		return true
	return false
