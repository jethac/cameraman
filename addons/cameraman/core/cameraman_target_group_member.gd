@tool
class_name CameramanTargetGroupMember
## Resource describing one target node, its framing weight, and its radius.
extends Resource

## NodePath resolved against the edited scene root to find this target.
@export var target_path: NodePath
## Relative contribution of this target to weighted group calculations.
@export var weight: float = 1.0
## Extra radius in meters included around this target in group bounds.
@export var radius: float = 0.0
var target: Node3D

## Resolves target_path against root and returns the referenced Node3D.
func resolve(root: Node) -> Node3D:
	if target == null and not target_path.is_empty():
		target = root.get_node_or_null(target_path) as Node3D
	return target
