@tool
class_name CameramanComponent
## Defines the component contract for BODY, AIM, NOISE, and FINALIZE camera pipeline stages.
extends Node

var vcam: Node:
	get:
		return get_parent()

var follow_target: Node3D:
	get:
		return vcam.call("get_follow") as Node3D if vcam != null else null

var look_at_target: Node3D:
	get:
		return vcam.call("get_look_at") as Node3D if vcam != null else null

var follow_target_position: Vector3:
	get:
		return follow_target.global_position if follow_target != null else Vector3.ZERO

var follow_target_rotation: Quaternion:
	get:
		return (
			follow_target.global_transform.basis.get_rotation_quaternion()
			if follow_target != null
			else Quaternion.IDENTITY
		)

var look_at_target_position: Vector3:
	get:
		return look_at_target.global_position if look_at_target != null else Vector3.ZERO

## Returns the pipeline stage handled by this type.
func stage() -> CameramanCore.Stage:
	push_error("Component must implement stage")
	return CameramanCore.Stage.BODY

## Returns whether this object is valid for evaluation.
func is_valid() -> bool:
	return true

## Returns whether this component runs after the aim stage.
func body_applies_after_aim() -> bool:
	return false

## Applies this extension before the component pipeline runs.
func pre_pipeline_mutate_camera_state(
	_state: CameramanCameraState,
	_delta: float
) -> void:
	pass

## Applies this component's camera-state mutation for the current pipeline step.
func mutate_camera_state(_state: CameramanCameraState, _delta: float) -> void:
	push_error("Component must implement mutate_camera_state")

## Handles the transition from camera event.
func on_transition_from_camera(
	_from: Object,
	_world_up: Vector3,
	_delta: float
) -> bool:
	return false

## Handles the target object warped event.
func on_target_object_warped(_target: Node3D, _delta: Vector3) -> void:
	pass

## Forces the camera and its pipeline state to a position and rotation.
func force_camera_position(_position: Vector3, _rotation: Quaternion) -> void:
	pass

## Returns the longest damping time configured by this type.
func get_max_damp_time() -> float:
	return 0.0

## Returns the input axes.
func get_input_axes() -> Array[Dictionary]:
	return []
