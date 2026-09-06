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

func _handles(object: Object) -> bool:
	return object is CameramanCamera or object is CameramanComponent

func _edit(_object: Object) -> void:
	update_overlays()

func _forward_3d_draw_over_viewport(overlay: Control) -> void:
	var selected: Node = _selected_node()
	if selected == null:
		return
	var camera: CameramanCamera = selected as CameramanCamera
	if camera == null and selected != null:
		camera = selected.get_parent() as CameramanCamera
	if camera == null:
		return
	var composer: CameramanRotationComposer
	for child in camera.get_children():
		if child is CameramanRotationComposer:
			composer = child as CameramanRotationComposer
			break
	if composer == null or composer.composition == null:
		return
	var zone: Vector2 = composer.composition.dead_zone_size * overlay.size
	var center: Vector2 = composer.composition.screen_position * overlay.size
	overlay.draw_rect(Rect2(center - zone * 0.5, zone), Color(0.2, 0.8, 1.0, 0.5), false, 2.0)

func _selected_node() -> Node:
	var selection: EditorSelection = get_editor_interface().get_selection()
	var selected: Array[Node] = selection.get_selected_nodes()
	return selected[0] if not selected.is_empty() else get_editor_interface().get_edited_scene_root()

func _selected_parent() -> Node:
	var parent: Node = _selected_node()
	if parent == null:
		push_warning("Cameraman preset requires an edited scene root or selected parent.")
	return parent

func _commit_nodes(action_name: String, parent: Node, nodes: Array[Node]) -> void:
	if parent == null or nodes.is_empty():
		return
	var undo: EditorUndoRedoManager = get_undo_redo()
	undo.create_action(action_name)
	for node in nodes:
		undo.add_do_method(parent, "add_child", node)
		undo.add_do_method(self, "_own_recursive", node)
		undo.add_do_reference(node)
		undo.add_undo_method(parent, "remove_child", node)
	undo.commit_action()

func _own_recursive(node: Node) -> void:
	var scene_root: Node = get_editor_interface().get_edited_scene_root()
	if scene_root == null:
		return
	if node != scene_root:
		node.owner = scene_root
	for child in node.get_children():
		_own_recursive(child)

func _create_brain() -> void:
	var selected: Node = _selected_node()
	if selected == null:
		push_warning("Cannot create a brain without an edited scene root or selected parent.")
		return
	var camera: Camera3D = selected as Camera3D
	var nodes: Array[Node] = []
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		nodes.append(camera)
	var brain: CameramanBrain = CameramanBrain.new()
	brain.name = "CameramanBrain"
	if nodes.is_empty():
		_commit_nodes("Create Brain", camera, [brain])
	else:
		camera.add_child(brain)
		_commit_nodes("Create Brain", selected, nodes)

func _create_camera() -> void:
	var parent: Node = _selected_parent()
	if parent == null:
		return
	var camera: CameramanCamera = CameramanCamera.new()
	camera.name = "CameramanCamera"
	_add_component(camera, CameramanFollow.new(), "Follow")
	_add_component(camera, CameramanRotationComposer.new(), "RotationComposer")
	_commit_nodes("Create Camera", parent, [camera])

func _create_free_look() -> void:
	var parent: Node = _selected_parent()
	if parent == null:
		return
	var camera: CameramanCamera = CameramanCamera.new()
	camera.name = "FreeLookCamera"
	_add_component(camera, CameramanOrbitalFollow.new(), "OrbitalFollow")
	_add_component(camera, CameramanRotationComposer.new(), "RotationComposer")
	_add_component(camera, CameramanInputAxisController.new(), "InputAxisController")
	_commit_nodes("Create FreeLook", parent, [camera])

func _create_third_person() -> void:
	var parent: Node = _selected_parent()
	if parent == null:
		return
	var camera: CameramanCamera = CameramanCamera.new()
	camera.name = "ThirdPersonCamera"
	_add_component(camera, CameramanThirdPersonFollow.new(), "ThirdPersonFollow")
	_commit_nodes("Create ThirdPerson", parent, [camera])

func _create_dolly() -> void:
	var parent: Node = _selected_parent()
	if parent == null:
		return
	var path: Path3D = Path3D.new()
	path.name = "CameraPath"
	var curve: Curve3D = Curve3D.new()
	curve.add_point(Vector3(0.0, 2.0, 8.0))
	curve.add_point(Vector3(0.0, 4.0, 0.0))
	curve.add_point(Vector3(0.0, 2.0, -8.0))
	path.curve = curve
	var camera: CameramanCamera = CameramanCamera.new()
	camera.name = "DollyCamera"
	_add_component(camera, CameramanSplineDolly.new(), "SplineDolly")
	_commit_nodes("Create Dolly", parent, [path, camera])

func _create_2d_camera() -> void:
	var parent: Node = _selected_parent()
	if parent == null:
		return
	var output: Camera2D = Camera2D.new()
	output.name = "Camera2D"
	var brain: CameramanBrain2D = CameramanBrain2D.new()
	brain.name = "CameramanBrain2D"
	output.add_child(brain)
	var camera: CameramanCamera = CameramanCamera.new()
	camera.name = "Camera2DVirtualCamera"
	_add_component(camera, CameramanFollow.new(), "Follow")
	_add_component(camera, CameramanPositionComposer.new(), "PositionComposer")
	_commit_nodes("Create 2D Camera", parent, [output, camera])

func _create_clear_shot() -> void:
	_add_manager(CameramanClearShot.new(), "ClearShot")

func _create_state_driven() -> void:
	_add_manager(CameramanStateDrivenCamera.new(), "StateDrivenCamera")

func _create_sequencer() -> void:
	_add_manager(CameramanSequencerCamera.new(), "SequencerCamera")

func _create_mixing() -> void:
	_add_manager(CameramanMixingCamera.new(), "MixingCamera")

func _create_target_group() -> void:
	var parent: Node = _selected_parent()
	if parent == null:
		return
	var group: CameramanTargetGroup = CameramanTargetGroup.new()
	group.name = "TargetGroup"
	_commit_nodes("Create TargetGroup", parent, [group])

func _create_impulse_source() -> void:
	var parent: Node = _selected_parent()
	if parent == null:
		return
	var source: CameramanImpulseSource = CameramanImpulseSource.new()
	source.name = "ImpulseSource"
	_commit_nodes("Create Impulse Source", parent, [source])

func _add_manager(manager: Node, manager_name: String) -> void:
	manager.name = manager_name
	var parent: Node = _selected_parent()
	if parent == null:
		return
	_commit_nodes("Create %s" % manager_name, parent, [manager])

func _add_component(camera: Node, component: Node, component_name: String) -> void:
	component.name = component_name
	camera.add_child(component)
