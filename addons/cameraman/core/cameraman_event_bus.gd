@tool
class_name CameramanEventBus
## Provides the event bus runtime helper.
extends RefCounted

signal camera_activated(params: CameramanActivationEvent)
signal camera_deactivated(mixer: Node, camera: Object)
signal blend_created(params: CameramanBlendEvent)
signal blend_finished(mixer: Node, camera: Object)
signal camera_updated(brain: Node)

## Emits a camera activation event.
func emit_activation(params: CameramanActivationEvent) -> void:
	camera_activated.emit(params)

## Emits a camera blend event.
func emit_blend(params: CameramanBlendEvent) -> void:
	blend_created.emit(params)
