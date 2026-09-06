@tool
class_name CameramanCustomBlend
## Resource mapping source and destination camera names to a blend definition.
extends Resource

## Source camera name pattern; wildcard rules may match any source.
@export var from_name: String = "**ANY CAMERA**"
## Destination camera name pattern; wildcard rules may match any destination.
@export var to_name: String = "**ANY CAMERA**"
## Blend definition returned when both name patterns match.
@export var definition: CameramanBlendDefinition
