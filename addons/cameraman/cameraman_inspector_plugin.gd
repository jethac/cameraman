@tool
class_name CameramanInspectorPlugin
extends EditorInspectorPlugin

func _can_handle(object: Object) -> bool:
	return object is CameramanVirtualCameraBase

func _parse_begin(object: Object) -> void:
	var button: Button = Button.new()
	button.text = "Solo"
	button.pressed.connect(func() -> void:
		CameramanCore.solo_camera = null if CameramanCore.solo_camera == object else object
	)
	add_custom_control(button)
