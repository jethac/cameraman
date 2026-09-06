@tool
class_name CameramanTargetGroupMember
## Provides the target group member configuration resource.
## Key properties include `target_path`, `weight`, `radius`, which configure its behavior.
extends Resource

## Identifies the scene node used for the target reference.
@export var target_path: NodePath
## Configures the weight used by this type.
@export var weight: float = 1.0
## Sets the radius used by this type.
@export var radius: float = 0.0
var target: Node3D

## Resolves the target node from the supplied scene root.
func resolve(root: Node) -> Node3D:
	if target == null and not target_path.is_empty():
		target = root.get_node_or_null(target_path) as Node3D
	return target
