@tool
class_name CameramanCameraEvents
## Forwards virtual-camera activation signals to scene-tree callbacks.
extends Node

signal camera_activated(event: CameramanActivationEvent)
signal camera_deactivated(mixer: Node, camera: Object)
signal blend_created(params: CameramanBlendEvent)
signal blend_finished(mixer: Node, camera: Object)
signal camera_cut(brain: CameramanBrain)

## Virtual camera whose activation signals are forwarded by this node.
@export var camera: CameramanVirtualCameraBase

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if camera == null:
		camera = get_parent() as CameramanVirtualCameraBase
	if camera != null:
		camera.activated.connect(_on_activated)
		camera.deactivated.connect(_on_deactivated)

func _on_activated(event: CameramanActivationEvent) -> void:
	camera_activated.emit(event)

func _on_deactivated(event: CameramanActivationEvent) -> void:
	camera_deactivated.emit(event.origin, event.outgoing)
