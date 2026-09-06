@tool
class_name CameramanGizmoPlugin
## Provides the gizmo plugin Godot editor integration.
extends EditorNode3DGizmoPlugin

func _init() -> void:
	create_material("frustum", Color(0.2, 0.8, 1.0, 0.8))

func _get_gizmo_name() -> String:
	return "CameramanCamera"

func _has_gizmo(node: Node3D) -> bool:
	return node is CameramanCamera

func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	var camera: CameramanCamera = gizmo.get_node_3d() as CameramanCamera
	if camera == null:
		return
	var lens: CameramanLens = camera.lens if camera.lens != null else CameramanLens.new()
	var aspect: float = CameramanCameraState.aspect_ratio
	if aspect <= 0.0:
		aspect = 16.0 / 9.0
	var near_distance: float = lens.near
	var far_distance: float = minf(lens.far, 100.0)
	var near_height: float = tan(deg_to_rad(lens.fov_degrees) * 0.5) * near_distance
	var far_height: float = tan(deg_to_rad(lens.fov_degrees) * 0.5) * far_distance
	var near_width: float = near_height * aspect
	var far_width: float = far_height * aspect
	var near_points: Array[Vector3] = _frustum_points(near_distance, near_width, near_height)
	var far_points: Array[Vector3] = _frustum_points(far_distance, far_width, far_height)
	var points := PackedVector3Array()
	for index in range(4):
		points.append(near_points[index])
		points.append(near_points[(index + 1) % 4])
		points.append(far_points[index])
		points.append(far_points[(index + 1) % 4])
		points.append(near_points[index])
		points.append(far_points[index])
	gizmo.add_lines(points, get_material("frustum", gizmo))

func _frustum_points(depth: float, half_width: float, half_height: float) -> Array[Vector3]:
	return [
		Vector3(-half_width, -half_height, -depth),
		Vector3(half_width, -half_height, -depth),
		Vector3(half_width, half_height, -depth),
		Vector3(-half_width, half_height, -depth)
	]
