@tool
class_name CameramanTargetGroupMember
extends Resource

@export var target_path: NodePath
@export var weight: float = 1.0
@export var radius: float = 0.0
var target: Node3D

func resolve(root: Node) -> Node3D:
	if target == null and not target_path.is_empty():
		target = root.get_node_or_null(target_path) as Node3D
	return target
