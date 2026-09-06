class_name CameramanBrainEvents
extends Node

signal camera_activated(brain: CameramanBrain, incoming: Object, outgoing: Object)
signal camera_deactivated(mixer: Node, camera: Object)
signal blend_created(params: CameramanBlendEvent)
signal blend_finished(mixer: Node, camera: Object)
signal camera_cut(brain: CameramanBrain)

@export var brain: CameramanBrain

func _ready() -> void:
	if brain == null:
		brain = get_parent() as CameramanBrain
	if brain != null:
		brain.camera_activated.connect(_on_camera_activated)
		brain.camera_cut.connect(_on_camera_cut)
		CameramanCore.get_events().blend_created.connect(_on_blend_created)
		CameramanCore.get_events().camera_deactivated.connect(_on_camera_deactivated)
		CameramanCore.get_events().blend_finished.connect(_on_blend_finished)

func _on_camera_activated(
	owner_brain: CameramanBrain,
	incoming: Object,
	outgoing: Object
) -> void:
	if owner_brain == brain:
		camera_activated.emit(owner_brain, incoming, outgoing)

func _on_camera_cut(owner_brain: CameramanBrain) -> void:
	if owner_brain == brain:
		camera_cut.emit(owner_brain)

func _on_blend_created(params: CameramanBlendEvent) -> void:
	if params.origin == brain:
		blend_created.emit(params)

func _on_camera_deactivated(owner: Node, camera: Object) -> void:
	if owner == brain:
		camera_deactivated.emit(owner, camera)

func _on_blend_finished(owner: Node, camera: Object) -> void:
	if owner == brain:
		blend_finished.emit(owner, camera)
