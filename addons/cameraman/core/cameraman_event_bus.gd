@tool
class_name CameramanEventBus
## Publishes activation, blend, and blend-completion events for Cameraman systems.
extends RefCounted

signal camera_activated(params: CameramanActivationEvent)
signal camera_deactivated(mixer: Node, camera: Object)
signal blend_created(params: CameramanBlendEvent)
signal blend_finished(mixer: Node, camera: Object)
signal camera_updated(brain: Node)

## Emits a camera activation event to the global event bus.
func emit_activation(params: CameramanActivationEvent) -> void:
	camera_activated.emit(params)

## Emits a blend-start event to the global event bus.
func emit_blend(params: CameramanBlendEvent) -> void:
	blend_created.emit(params)
