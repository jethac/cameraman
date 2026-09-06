@tool
class_name CameramanBlenderSettings
## Provides the blender settings configuration resource.
## Key properties include `custom_blends`, which configure its behavior.
extends Resource

## Defines the blend behavior used by custom blends.
@export var custom_blends: Array[CameramanCustomBlend] = []

## Returns the blend for.
func get_blend_for(
	from_name: String,
	to_name: String,
	default_definition: CameramanBlendDefinition
) -> CameramanBlendDefinition:
	var best: CameramanBlendDefinition = default_definition
	var best_specificity: int = -1
	for custom_blend in custom_blends:
		if custom_blend == null or custom_blend.definition == null:
			continue
		var from_matches: bool = custom_blend.from_name == from_name or custom_blend.from_name == "**ANY CAMERA**"
		var to_matches: bool = custom_blend.to_name == to_name or custom_blend.to_name == "**ANY CAMERA**"
		if not from_matches or not to_matches:
			continue
		var specificity: int = int(custom_blend.from_name == from_name) * 2 + int(
			custom_blend.to_name == to_name
		)
		if specificity > best_specificity:
			best_specificity = specificity
			best = custom_blend.definition
	return best
