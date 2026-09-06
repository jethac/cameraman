@tool
class_name CameramanCustomBlend
## Provides the custom blend configuration resource.
## Key properties include `from_name`, `to_name`, `definition`, which configure its behavior.
extends Resource

## Configures the from name used by this type.
@export var from_name: String = "**ANY CAMERA**"
## Configures the to name used by this type.
@export var to_name: String = "**ANY CAMERA**"
## Configures the definition used by this type.
@export var definition: CameramanBlendDefinition
