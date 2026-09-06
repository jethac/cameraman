class_name CameramanMixingCamera
extends CameramanCameraManagerBase

@export var weights: Array[float] = []

func internal_update_state(world_up: Vector3, delta: float) -> void:
	var result: CameramanCameraState
	var total: float = 0.0
	var index: int = 0
	var children: Array[CameramanVirtualCameraBase] = get_child_cameras()
	if children.size() > 8:
		children.resize(8)
	for child in children:
		child.update_state(world_up, delta)
		var weight: float = get_weight(index)
		index += 1
		if weight <= 0.0:
			continue
		if result == null:
			result = child.get_state()
			total = weight
		else:
			var next_total: float = total + weight
			result = CameramanCameraState.lerp(result, child.get_state(), weight / next_total)
			total = next_total
	if result == null:
		result = CameramanCameraState.create_default(world_up)
	_manager_state = result
	_state = result
	live_child = _first_weighted_child()
	previous_state_is_valid = true

func is_live_child(camera: CameramanVirtualCameraBase) -> bool:
	var index: int = get_child_cameras().find(camera)
	return index >= 0 and index < 8 and get_weight(index) > 0.0

func set_weight(index_or_camera: Variant, weight: float) -> void:
	var index: int = int(index_or_camera) if index_or_camera is int else get_child_cameras().find(index_or_camera)
	if index < 0 or index >= 8:
		return
	while weights.size() <= index:
		weights.append(0.0)
	weights[index] = maxf(weight, 0.0)

func get_weight(index: int) -> float:
	return weights[index] if index >= 0 and index < weights.size() else 0.0

func _first_weighted_child() -> CameramanVirtualCameraBase:
	var children: Array[CameramanVirtualCameraBase] = get_child_cameras()
	if children.size() > 8:
		children.resize(8)
	for index in range(children.size()):
		if get_weight(index) > 0.0:
			return children[index]
	return null
