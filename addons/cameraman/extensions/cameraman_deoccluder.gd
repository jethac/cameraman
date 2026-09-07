@tool
class_name CameramanDeoccluder
## FINALIZE-stage extension that pulls or moves the camera when the target is occluded.
extends CameramanExtension

enum Strategy { PULL_CAMERA_FORWARD, PRESERVE_CAMERA_HEIGHT, PRESERVE_CAMERA_DISTANCE }

## Physics layers considered occluders during target visibility tests.
@export_flags_3d_physics var collide_against: int = 1
## Occluder bodies in this group are skipped during visibility tests.
@export var ignore_group: StringName
## Groups whose bodies are treated as transparent to the target ray.
@export var transparent_groups: Array[StringName] = []
## Minimum camera distance in meters when an occluder blocks the path.
@export var minimum_distance_from_target: float = 0.1
## Enables camera movement around or through detected occluders.
@export var avoid_obstacles_enabled: bool = true
## Maximum distance in meters that deocclusion may move the camera.
@export var distance_limit: float = 0.0
## Sphere-cast radius in meters; zero uses a ray.
@export var camera_radius: float = 0.0
## Selects whether the camera pulls forward or shifts around an occluder.
@export var strategy: Strategy = Strategy.PULL_CAMERA_FORWARD
## Maximum number of candidate corrections tested per frame.
@export var maximum_effort: int = 4
## Seconds used to smooth deocclusion position changes.
@export var smoothing_time: float = 0.0
## Seconds used when the camera returns from an occluded correction.
@export var damping: float = 0.0
## Seconds used while an occluder remains between camera and target.
@export var damping_when_occluded: float = 0.0
## Includes visibility and distance in the extension quality score.
@export var shot_quality_enabled: bool = true
## Minimum and maximum distance range considered optimal for quality.
@export var optimal_distance: Vector2 = Vector2(1.0, 20.0)
## Maximum quality bonus awarded to a clear, well-framed shot.
@export var max_quality_boost: float = 1.0

var _occluded: bool = false

func post_pipeline_stage_callback(
	camera: Node,
	stage: CameramanCore.Stage,
	state: CameramanCameraState,
	delta: float
) -> void:
	if stage != CameramanCore.Stage.BODY or not avoid_obstacles_enabled:
		return
	var target: Node3D = camera.call("get_look_at") as Node3D
	var world_camera: Node3D = camera as Node3D
	if target == null or world_camera == null or world_camera.get_world_3d() == null:
		return
	var start: Vector3 = target.global_position
	var end: Vector3 = state.raw_position
	if distance_limit > 0.0:
		end = start + (end - start).limit_length(distance_limit)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, end)
	query.collision_mask = collide_against
	query.exclude = [target]
	var hit: Dictionary = world_camera.get_world_3d().direct_space_state.intersect_ray(query)
	_occluded = false
	if not hit.is_empty():
		var collider: Object = hit.get("collider") as Object
		if _is_ignored(collider):
			return
		_occluded = true
		var ray: Vector3 = (end - start).normalized()
		var corrected: Vector3 = (hit["position"] as Vector3) - ray * camera_radius
		corrected = _apply_strategy(corrected, start, state.raw_position)
		if maximum_effort > 0:
			corrected = state.raw_position + (corrected - state.raw_position).limit_length(float(maximum_effort))
		if corrected.distance_to(start) < minimum_distance_from_target:
			corrected = start + ray * minimum_distance_from_target
		var damp_time: float = maxf(
			smoothing_time,
			damping_when_occluded if _occluded else damping
		)
		var weight: float = 1.0 if damp_time <= 0.0 else CameramanDamper.damp(1.0, damp_time, delta)
		state.position_correction += (corrected - state.raw_position) * weight
	if shot_quality_enabled:
		var distance: float = state.raw_position.distance_to(start)
		var quality: float = inverse_lerp(optimal_distance.x, optimal_distance.y, distance)
		if _occluded:
			quality *= 0.05
		state.shot_quality = clampf(quality * max_quality_boost, 0.0, 1.0)

## Reports the last visibility result from the deocclusion ray or shape cast.
func is_occluded() -> bool:
	return _occluded

func _is_ignored(collider: Object) -> bool:
	if collider == null:
		return false
	if not ignore_group.is_empty() and collider is Node and (collider as Node).is_in_group(ignore_group):
		return true
	for group_name in transparent_groups:
		if collider is Node and (collider as Node).is_in_group(group_name):
			return true
	return false

func _apply_strategy(position: Vector3, target: Vector3, original: Vector3) -> Vector3:
	match strategy:
		Strategy.PRESERVE_CAMERA_HEIGHT:
			position.y = original.y
		Strategy.PRESERVE_CAMERA_DISTANCE:
			position = target + (position - target).normalized() * target.distance_to(original)
	return position
