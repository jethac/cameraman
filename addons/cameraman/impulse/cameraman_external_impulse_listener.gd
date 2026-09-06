class_name CameramanExternalImpulseListener
extends Node3D

@export_flags_3d_physics var channel_mask: int = 1
@export var gain: float = 1.0
@export var use_2d_distance: bool = false
@export var use_camera_space: bool = false

func _process(_delta: float) -> void:
	var result: Array[Variant] = CameramanCore.get_impulse_manager().get_impulse_at(
		global_position,
		use_2d_distance,
		channel_mask
	)
	var position_signal: Vector3 = result[0] as Vector3
	var rotation_signal: Quaternion = result[1] as Quaternion
	global_position += position_signal * gain
	global_basis = (global_basis * Basis(rotation_signal)).orthonormalized()
