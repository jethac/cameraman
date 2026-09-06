class_name CameramanObstacleAvoidance
extends Resource

@export var enabled: bool = false
@export_flags_3d_physics var collision_mask: int = 1
@export var camera_radius: float = 0.2
@export var damping_into: float = 0.1
@export var damping_from_collision: float = 0.2
@export var minimum_distance_from_target: float = 0.0
@export var ignore_group: StringName
