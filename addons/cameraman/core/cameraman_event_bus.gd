@tool
class_name CameramanEventBus
extends RefCounted

signal camera_activated(params: CameramanActivationEvent)
signal camera_deactivated(mixer: Node, camera: Object)
signal blend_created(params: CameramanBlendEvent)
signal blend_finished(mixer: Node, camera: Object)
signal camera_updated(brain: Node)

func emit_activation(params: CameramanActivationEvent) -> void:
	camera_activated.emit(params)

func emit_blend(params: CameramanBlendEvent) -> void:
	blend_created.emit(params)
