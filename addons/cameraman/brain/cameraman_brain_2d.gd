class_name CameramanBrain2D
extends CameramanBrain

@export var pixel_perfect: bool = false

func _apply_state(state: CameramanCameraState) -> void:
	var output: Camera2D = _get_output_camera_2d()
	if output == null:
		return
	var position: Vector2 = Vector2(state.get_final_position().x, state.get_final_position().y)
	if pixel_perfect and not _has_pixel_perfect_extension():
		position = position.round()
	output.global_position = position
	output.rotation = deg_to_rad(state.lens.dutch_degrees) + state.get_final_orientation().get_euler().z
	output.zoom = Vector2.ONE * (get_viewport().get_visible_rect().size.y / (
		maxf(state.lens.orthographic_size * 2.0, 0.001)
	))

func _get_output_camera_2d() -> Camera2D:
	if not camera_path.is_empty():
		return get_node_or_null(camera_path) as Camera2D
	return get_parent() as Camera2D

func _has_pixel_perfect_extension() -> bool:
	if active_virtual_camera == null:
		return false
	for extension in active_virtual_camera.get_extensions():
		if extension is CameramanPixelPerfect:
			return true
	return false
