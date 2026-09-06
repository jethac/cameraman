@tool
class_name CameramanPlugin
extends EditorPlugin

const TYPES: Array[Dictionary] = [
	{"name": "CameramanBrain", "base": "Node",
		"script": "res://addons/cameraman/brain/cameraman_brain.gd", "icon": "brain"},
	{"name": "CameramanBrain2D", "base": "Node",
		"script": "res://addons/cameraman/brain/cameraman_brain_2d.gd", "icon": "brain"},
	{"name": "CameramanCamera", "base": "Node3D",
		"script": "res://addons/cameraman/cameras/cameraman_camera.gd", "icon": "camera"},
	{"name": "CameramanVirtualCameraBase", "base": "Node3D",
		"script": "res://addons/cameraman/cameras/cameraman_virtual_camera_base.gd", "icon": "camera"},
	{"name": "CameramanFollow", "base": "Node",
		"script": "res://addons/cameraman/components/cameraman_follow.gd", "icon": "component"},
	{"name": "CameramanHardLockToTarget", "base": "Node",
		"script": "res://addons/cameraman/components/cameraman_hard_lock_to_target.gd", "icon": "component"},
	{"name": "CameramanHardLookAt", "base": "Node",
		"script": "res://addons/cameraman/components/cameraman_hard_look_at.gd", "icon": "component"},
	{"name": "CameramanOrbitalFollow", "base": "Node",
		"script": "res://addons/cameraman/components/cameraman_orbital_follow.gd", "icon": "component"},
	{"name": "CameramanThirdPersonFollow", "base": "Node",
		"script": "res://addons/cameraman/components/cameraman_third_person_follow.gd", "icon": "component"},
	{"name": "CameramanRotationComposer", "base": "Node",
		"script": "res://addons/cameraman/components/cameraman_rotation_composer.gd", "icon": "component"},
	{"name": "CameramanPositionComposer", "base": "Node",
		"script": "res://addons/cameraman/components/cameraman_position_composer.gd", "icon": "component"},
	{"name": "CameramanBasicMultiChannelPerlin", "base": "Node",
		"script": "res://addons/cameraman/components/cameraman_basic_multi_channel_perlin.gd", "icon": "component"},
	{"name": "CameramanPanTilt", "base": "Node",
		"script": "res://addons/cameraman/components/cameraman_pan_tilt.gd", "icon": "component"},
	{"name": "CameramanRotateWithFollowTarget", "base": "Node",
		"script": "res://addons/cameraman/components/cameraman_rotate_with_follow_target.gd", "icon": "component"},
	{"name": "CameramanSplineDolly", "base": "Node",
		"script": "res://addons/cameraman/components/cameraman_spline_dolly.gd", "icon": "component"},
	{"name": "CameramanSplineCart", "base": "Node3D",
		"script": "res://addons/cameraman/components/cameraman_spline_cart.gd", "icon": "component"},
	{"name": "CameramanInputAxisController", "base": "Node",
		"script": "res://addons/cameraman/input/cameraman_input_axis_controller.gd", "icon": "component"},
	{"name": "CameramanImpulseListener", "base": "Node",
		"script": "res://addons/cameraman/components/cameraman_impulse_listener.gd", "icon": "impulse"},
	{"name": "CameramanDeoccluder", "base": "Node",
		"script": "res://addons/cameraman/extensions/cameraman_deoccluder.gd", "icon": "extension"},
	{"name": "CameramanConfiner2D", "base": "Node",
		"script": "res://addons/cameraman/extensions/cameraman_confiner_2d.gd", "icon": "extension"},
	{"name": "CameramanConfiner3D", "base": "Node",
		"script": "res://addons/cameraman/extensions/cameraman_confiner_3d.gd", "icon": "extension"},
	{"name": "CameramanFollowZoom", "base": "Node",
		"script": "res://addons/cameraman/extensions/cameraman_follow_zoom.gd", "icon": "extension"},
	{"name": "CameramanFreeLookModifier", "base": "Node",
		"script": "res://addons/cameraman/extensions/cameraman_free_look_modifier.gd", "icon": "extension"},
	{"name": "CameramanGroupFraming", "base": "Node",
		"script": "res://addons/cameraman/extensions/cameraman_group_framing.gd", "icon": "extension"},
	{"name": "CameramanRecomposer", "base": "Node",
		"script": "res://addons/cameraman/extensions/cameraman_recomposer.gd", "icon": "extension"},
	{"name": "CameramanStoryboard", "base": "Node",
		"script": "res://addons/cameraman/extensions/cameraman_storyboard.gd", "icon": "extension"},
	{"name": "CameramanThirdPersonAim", "base": "Node",
		"script": "res://addons/cameraman/extensions/cameraman_third_person_aim.gd", "icon": "extension"},
	{"name": "CameramanShotQualityEvaluator", "base": "Node",
		"script": "res://addons/cameraman/extensions/cameraman_shot_quality_evaluator.gd", "icon": "extension"},
	{"name": "CameramanCameraAttributes", "base": "Node",
		"script": "res://addons/cameraman/extensions/cameraman_camera_attributes.gd", "icon": "extension"},
	{"name": "CameramanPixelPerfect", "base": "Node",
		"script": "res://addons/cameraman/extensions/cameraman_pixel_perfect.gd", "icon": "extension"},
	{"name": "CameramanImpulseSource", "base": "Node3D",
		"script": "res://addons/cameraman/impulse/cameraman_impulse_source.gd", "icon": "impulse"},
	{"name": "CameramanCollisionImpulseSource", "base": "Node3D",
		"script": "res://addons/cameraman/impulse/cameraman_collision_impulse_source.gd", "icon": "impulse"},
	{"name": "CameramanExternalImpulseListener", "base": "Node3D",
		"script": "res://addons/cameraman/impulse/cameraman_external_impulse_listener.gd", "icon": "impulse"},
	{"name": "CameramanTargetGroup", "base": "Node3D",
		"script": "res://addons/cameraman/core/cameraman_target_group.gd", "icon": "component"},
	{"name": "CameramanCameraManagerBase", "base": "Node3D",
		"script": "res://addons/cameraman/managers/cameraman_camera_manager_base.gd", "icon": "manager"},
	{"name": "CameramanClearShot", "base": "Node3D",
		"script": "res://addons/cameraman/managers/cameraman_clear_shot.gd", "icon": "manager"},
	{"name": "CameramanStateDrivenCamera", "base": "Node3D",
		"script": "res://addons/cameraman/managers/cameraman_state_driven_camera.gd", "icon": "manager"},
	{"name": "CameramanSequencerCamera", "base": "Node3D",
		"script": "res://addons/cameraman/managers/cameraman_sequencer_camera.gd", "icon": "manager"},
	{"name": "CameramanMixingCamera", "base": "Node3D",
		"script": "res://addons/cameraman/managers/cameraman_mixing_camera.gd", "icon": "manager"},
	{"name": "CameramanShot", "base": "Node",
		"script": "res://addons/cameraman/timeline/cameraman_shot.gd", "icon": "timeline"},
	{"name": "CameramanShotSequence", "base": "Node",
		"script": "res://addons/cameraman/timeline/cameraman_shot_sequence.gd", "icon": "timeline"}
]

var _inspector: CameramanInspectorPlugin
var _gizmo: CameramanGizmoPlugin

func _enter_tree() -> void:
	for type_info in TYPES:
		add_custom_type(
			type_info.name,
			type_info.base,
			load(type_info.script),
			load("res://addons/cameraman/icons/%s.svg" % type_info.icon)
		)
	add_tool_menu_item("Create Brain", _create_brain)
	add_tool_menu_item("Create Camera", _create_camera)
	add_tool_menu_item("Create FreeLook", _create_free_look)
	add_tool_menu_item("Create ThirdPerson", _create_third_person)
	add_tool_menu_item("Create Dolly", _create_dolly)
	add_tool_menu_item("Create 2D Camera", _create_2d_camera)
	add_tool_menu_item("Create ClearShot", _create_clear_shot)
	add_tool_menu_item("Create StateDriven", _create_state_driven)
	add_tool_menu_item("Create Sequencer", _create_sequencer)
	add_tool_menu_item("Create Mixing", _create_mixing)
	add_tool_menu_item("Create TargetGroup", _create_target_group)
	add_tool_menu_item("Create Impulse Source", _create_impulse_source)
	_inspector = CameramanInspectorPlugin.new()
	add_inspector_plugin(_inspector)
	_gizmo = CameramanGizmoPlugin.new()
	add_node_3d_gizmo_plugin(_gizmo)

func _exit_tree() -> void:
	for type_info in TYPES:
		remove_custom_type(type_info.name)
	for menu_name in [
		"Create Brain", "Create Camera", "Create FreeLook", "Create ThirdPerson",
		"Create Dolly", "Create 2D Camera", "Create ClearShot", "Create StateDriven",
		"Create Sequencer", "Create Mixing", "Create TargetGroup", "Create Impulse Source"
	]:
		remove_tool_menu_item(menu_name)
	if _inspector != null:
		remove_inspector_plugin(_inspector)
	if _gizmo != null:
		remove_node_3d_gizmo_plugin(_gizmo)

func _forward_3d_draw_over_viewport(overlay: Control) -> void:
	var selected: Node = _selected_node()
	var camera: CameramanCamera = selected as CameramanCamera
	if camera == null:
		camera = selected.get_parent() as CameramanCamera
	if camera == null:
		return
	var composer: CameramanRotationComposer = camera.get_node_or_null("RotationComposer") as CameramanRotationComposer
	if composer == null:
		composer = camera.find_child("CameramanRotationComposer", true, false) as CameramanRotationComposer
	if composer == null:
		return
	var zone: Vector2 = composer.composition.dead_zone_size * overlay.size
	var center: Vector2 = composer.composition.screen_position * overlay.size
	overlay.draw_rect(Rect2(center - zone * 0.5, zone), Color(0.2, 0.8, 1.0, 0.5), false, 2.0)

func _selected_node() -> Node:
	var selection: EditorSelection = get_editor_interface().get_selection()
	var selected: Array[Node] = selection.get_selected_nodes()
	return selected[0] if not selected.is_empty() else get_editor_interface().get_edited_scene_root()

func _add_node(parent: Node, node: Node) -> void:
	var undo: EditorUndoRedoManager = get_undo_redo()
	undo.create_action("Create %s" % node.name)
	undo.add_do_method(parent, "add_child", node)
	undo.add_do_method(node, "set_owner", get_editor_interface().get_edited_scene_root())
	undo.add_undo_method(parent, "remove_child", node)
	undo.commit_action()

func _create_brain() -> void:
	var selected: Node = _selected_node()
	var camera: Camera3D = selected as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		_add_node(selected, camera)
	var brain: CameramanBrain = CameramanBrain.new()
	brain.name = "CameramanBrain"
	_add_node(camera, brain)

func _create_camera() -> void:
	var parent: Node = _selected_node()
	var camera: CameramanCamera = CameramanCamera.new()
	camera.name = "CameramanCamera"
	_add_node(parent, camera)
	_add_component(camera, CameramanFollow.new(), "Follow")
	_add_component(camera, CameramanRotationComposer.new(), "RotationComposer")

func _create_free_look() -> void:
	var parent: Node = _selected_node()
	var camera: CameramanCamera = CameramanCamera.new()
	camera.name = "FreeLookCamera"
	_add_node(parent, camera)
	_add_component(camera, CameramanOrbitalFollow.new(), "OrbitalFollow")
	_add_component(camera, CameramanRotationComposer.new(), "RotationComposer")
	_add_component(camera, CameramanInputAxisController.new(), "InputAxisController")

func _create_third_person() -> void:
	var parent: Node = _selected_node()
	var camera: CameramanCamera = CameramanCamera.new()
	camera.name = "ThirdPersonCamera"
	_add_node(parent, camera)
	_add_component(camera, CameramanThirdPersonFollow.new(), "ThirdPersonFollow")

func _create_dolly() -> void:
	var parent: Node = _selected_node()
	var path: Path3D = Path3D.new()
	path.name = "CameraPath"
	var curve: Curve3D = Curve3D.new()
	curve.add_point(Vector3(0.0, 2.0, 8.0))
	curve.add_point(Vector3(0.0, 4.0, 0.0))
	curve.add_point(Vector3(0.0, 2.0, -8.0))
	path.curve = curve
	_add_node(parent, path)
	var camera: CameramanCamera = CameramanCamera.new()
	camera.name = "DollyCamera"
	_add_node(parent, camera)
	_add_component(camera, CameramanSplineDolly.new(), "SplineDolly")

func _create_2d_camera() -> void:
	var parent: Node = _selected_node()
	var output: Camera2D = Camera2D.new()
	output.name = "Camera2D"
	_add_node(parent, output)
	var brain: CameramanBrain2D = CameramanBrain2D.new()
	brain.name = "CameramanBrain2D"
	_add_node(output, brain)
	var camera: CameramanCamera = CameramanCamera.new()
	camera.name = "Camera2DVirtualCamera"
	_add_node(parent, camera)
	_add_component(camera, CameramanFollow.new(), "Follow")
	_add_component(camera, CameramanPositionComposer.new(), "PositionComposer")

func _create_clear_shot() -> void:
	_add_manager(CameramanClearShot.new(), "ClearShot")

func _create_state_driven() -> void:
	_add_manager(CameramanStateDrivenCamera.new(), "StateDrivenCamera")

func _create_sequencer() -> void:
	_add_manager(CameramanSequencerCamera.new(), "SequencerCamera")

func _create_mixing() -> void:
	_add_manager(CameramanMixingCamera.new(), "MixingCamera")

func _create_target_group() -> void:
	_add_node(_selected_node(), CameramanTargetGroup.new())

func _create_impulse_source() -> void:
	_add_node(_selected_node(), CameramanImpulseSource.new())

func _add_manager(manager: Node, manager_name: String) -> void:
	manager.name = manager_name
	_add_node(_selected_node(), manager)

func _add_component(camera: Node, component: Node, component_name: String) -> void:
	component.name = component_name
	_add_node(camera, component)
