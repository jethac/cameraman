@tool
class_name CameramanVirtualCameraBase
## Provides target binding, pipeline evaluation, extension dispatch, and registry behavior for
## virtual cameras.
extends Node3D

signal activated(event: CameramanActivationEvent)
signal deactivated(event: CameramanActivationEvent)

enum StandbyUpdate { NEVER, ALWAYS, ROUND_ROBIN }

## Includes priority in selection only when enabled; otherwise effective priority is zero.
@export var priority_enabled: bool = false
## Higher effective values win among eligible cameras on the same output channel.
@export var priority: int = 0
## Bitmask of brain output channels that may select this camera.
@export_flags("Channel 1") var output_channel: int = 1
## Controls whether inactive cameras update never, always, or round-robin.
@export var standby_update: StandbyUpdate = StandbyUpdate.ROUND_ROBIN
@export_flags(
	"Spherical", "Cylindrical", "Screen Aim", "Inherit Position", "Ignore Target", "Freeze Out"
) var blend_hint: int = 0

var previous_state_is_valid: bool = false
var follow_target_attachment: float = 1.0
var look_at_target_attachment: float = 1.0
var _state: CameramanCameraState = CameramanCameraState.create_default()
var _extensions: Array[CameramanExtension] = []
var _last_world_up: Vector3 = Vector3.UP
var _last_delta: float = 0.0

func get_camera_name() -> String:
	return name

func get_description() -> String:
	return get_camera_name()

func is_valid() -> bool:
	return is_inside_tree() and is_enabled()

func on_camera_activated(event: CameramanActivationEvent) -> void:
	activated.emit(event)
	for extension in _extensions:
		extension.on_camera_activated(self, event.outgoing)

func on_camera_deactivated(event: CameramanActivationEvent) -> void:
	deactivated.emit(event)
	for extension in _extensions:
		extension.on_camera_deactivated(self, event.incoming)

func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		CameramanCore.get_registry().add(self)
	_refresh_extensions()

func _ready() -> void:
	child_entered_tree.connect(_on_child_tree_changed)
	child_exiting_tree.connect(_on_child_tree_changed)
	_refresh_extensions()

func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		CameramanCore.get_registry().remove(self)

func _notification(what: int) -> void:
	if Engine.is_editor_hint():
		return
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if is_inside_tree():
			if visible:
				CameramanCore.get_registry().add(self)
			else:
				CameramanCore.get_registry().remove(self)

func get_follow() -> Node3D:
	return _find_inherited_target("follow")

func set_follow(target: Node3D) -> void:
	set_meta("cameraman_follow", target)

func get_look_at() -> Node3D:
	return _find_inherited_target("look_at")

func set_look_at(target: Node3D) -> void:
	set_meta("cameraman_look_at", target)

func get_follow_target_as_group() -> CameramanTargetGroup:
	var target: Node3D = get_follow()
	return target as CameramanTargetGroup

func get_look_at_target_as_group() -> CameramanTargetGroup:
	var target: Node3D = get_look_at()
	return target as CameramanTargetGroup

func get_state() -> CameramanCameraState:
	return _state

## Returns priority or zero when priority_enabled is false.
func get_effective_priority() -> int:
	return priority if priority_enabled else 0

## Evaluates components in pipeline order and stores the resulting camera state.
func update_state(world_up: Vector3, delta: float) -> void:
	if delta < 0.0:
		previous_state_is_valid = false
	_last_world_up = world_up
	_last_delta = delta
	internal_update_state(world_up, delta)

func internal_update_state(_world_up: Vector3, _delta: float) -> void:
	push_error("Virtual camera must implement internal_update_state")

func on_transition_from_camera(
	from: Object,
	world_up: Vector3,
	delta: float
) -> void:
	for extension in _extensions:
		extension.on_transition_from_camera(self, from, world_up, delta)
	for component in _get_components():
		component.on_transition_from_camera(from, world_up, delta)
	if (blend_hint & CameramanCore.BlendHint.INHERIT_POSITION) != 0 and from != null:
		var state: CameramanCameraState = from.call("get_state") as CameramanCameraState
		force_camera_position(state.get_final_position(), state.get_final_orientation())

## Forwards target displacement to components and extensions so damping can rebase.
func on_target_object_warped(target: Node3D, position_delta: Vector3) -> void:
	var rebases_on_target_warp: bool = false
	for component in _get_components():
		if component.rebases_on_target_warp():
			rebases_on_target_warp = true
			break
	if (
		target == get_follow()
		and not self is CameramanCameraManagerBase
		and rebases_on_target_warp
	):
		global_position += position_delta
	for extension in _extensions:
		extension.on_target_object_warped(self, target, position_delta)
	for component in _get_components():
		component.on_target_object_warped(target, position_delta)

## Writes a position and rotation to the node and all stateful pipeline children.
func force_camera_position(position: Vector3, rotation: Quaternion) -> void:
	global_position = position
	global_basis = Basis(rotation)
	for extension in _extensions:
		extension.force_camera_position(self, position, rotation)
	for component in _get_components():
		component.force_camera_position(position, rotation)

func get_max_damp_time() -> float:
	var maximum: float = 0.0
	for extension in _extensions:
		maximum = maxf(maximum, extension.get_max_damp_time())
	for component in _get_components():
		maximum = maxf(maximum, component.get_max_damp_time())
	return maximum

## Raises this camera above the current live camera and enables priority selection.
func prioritize() -> void:
	var brain: Node = CameramanCore.find_potential_target_brain(self)
	var maximum: int = priority
	if brain != null:
		for camera_node in CameramanCore.get_registry().get_cameras():
			var camera: CameramanVirtualCameraBase = camera_node as CameramanVirtualCameraBase
			if camera != null and brain.call("is_live", camera):
				maximum = maxi(maximum, camera.get_effective_priority())
	priority = maximum + 1
	priority_enabled = true
	CameramanCore.get_registry().mark_activated(self)

func is_live() -> bool:
	return CameramanCore.is_live(self)

## Adds an extension once and includes it in later pipeline callbacks.
func add_extension(extension: CameramanExtension) -> void:
	if extension != null and not _extensions.has(extension):
		_extensions.append(extension)

## Removes an extension so it no longer receives pipeline callbacks.
func remove_extension(extension: CameramanExtension) -> void:
	_extensions.erase(extension)

func get_extensions() -> Array[CameramanExtension]:
	_refresh_extensions()
	return _extensions.duplicate()

func invoke_post_pipeline_stage_callback(
	stage: CameramanCore.Stage,
	state: CameramanCameraState,
	delta: float
) -> void:
	for extension in _extensions:
		extension.post_pipeline_stage_callback(self, stage, state, delta)

func get_parent_mixer() -> Node:
	var current: Node = get_parent()
	while current != null:
		if current.has_method("is_cameraman_mixer") and current.is_cameraman_mixer():
			return current
		current = current.get_parent()
	return null

func is_enabled() -> bool:
	return is_inside_tree() and visible and process_mode != Node.PROCESS_MODE_DISABLED

func _find_inherited_target(kind: String) -> Node3D:
	var metadata_key: String = "cameraman_" + kind
	if has_meta(metadata_key):
		return get_meta(metadata_key) as Node3D
	var current: Node = get_parent()
	while current != null:
		if current.has_meta(metadata_key):
			return current.get_meta(metadata_key) as Node3D
		current = current.get_parent()
	return null

func _refresh_extensions() -> void:
	_extensions.clear()
	for child in get_children():
		var extension: CameramanExtension = child as CameramanExtension
		if extension != null:
			_extensions.append(extension)

func _on_child_tree_changed(_child: Node) -> void:
	_refresh_extensions()

func _get_components() -> Array[CameramanComponent]:
	var components: Array[CameramanComponent] = []
	for child in get_children():
		var component: CameramanComponent = child as CameramanComponent
		if component != null:
			components.append(component)
	return components
