@tool
class_name CameramanStateDrivenInstruction
## Provides the state driven instruction configuration resource.
## Key properties include `state_name`, `camera`, `activate_after`, and related settings, which configure its
## behavior.
extends Resource

## Configures the state name used by this type.
@export var state_name: StringName
## Configures the camera used by this type.
@export var camera: NodePath
## Configures the activate after used by this type.
@export var activate_after: float = 0.0
## Configures the min duration used by this type.
@export var min_duration: float = 0.0
