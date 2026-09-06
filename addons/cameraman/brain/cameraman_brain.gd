class_name CameramanBrain
extends Node

signal camera_cut(brain: CameramanBrain)
signal camera_activated(brain: CameramanBrain, incoming: Object, outgoing: Object)

enum UpdateMethod { PROCESS, PHYSICS, SMART, MANUAL }
enum BlendUpdateMethod { PROCESS, PHYSICS }

@export var camera_path: NodePath
@export var show_debug_text: bool = false
@export var show_camera_frustum: bool = true
@export var ignore_time_scale: bool = false
@export var world_up_override: Node3D
@export_flags("All Channels") var channel_mask: int = 0xFFFFFFFF
@export var update_method: UpdateMethod = UpdateMethod.SMART
@export var blend_update_method: BlendUpdateMethod = BlendUpdateMethod.PROCESS
@export var lens_mode_override_enabled: bool = false
@export var default_lens_mode: CameramanLens.Mode = CameramanLens.Mode.PERSPECTIVE
@export var default_blend: CameramanBlendDefinition
@export var custom_blends: CameramanBlenderSettings

var active_virtual_camera: CameramanVirtualCameraBase
var active_blend: CameramanBlend:
	get:
		return _blend_manager.active_blend
var is_blending: bool:
	get:
		return _blend_manager.active_blend != null
var current_camera_state: CameramanCameraState = CameramanCameraState.create_default()
var _blend_manager: CameramanBlendManager = CameramanBlendManager.new()
var _frame: int = 0
var _overrides: Dictionary = {}
var _next_override_id: int = 1
var _debug_label: Label
var _debug_layer: CanvasLayer
var _live_camera: CameramanVirtualCameraBase
var _standby_index: int = 0
var _update_tracker: CameramanUpdateTracker = CameramanUpdateTracker.new()
var _update_token: int = 0
var _frustum_mesh: ImmediateMesh
var _frustum_instance: MeshInstance3D

func _init() -> void:
	default_blend = CameramanBlendDefinition.new()

func _ready() -> void:
	process_priority = 1000
	CameramanCore.register_brain(self)

func _exit_tree() -> void:
	CameramanCore.unregister_brain(self)

func _process(delta: float) -> void:
	_record_target_transforms(false)
	if update_method == UpdateMethod.PROCESS:
		_update_frame(delta, Engine.get_process_frames())
	elif update_method == UpdateMethod.SMART and not _desired_source_is_physics_driven():
		_update_frame(delta, Engine.get_process_frames())

func _physics_process(delta: float) -> void:
	_record_target_transforms(true)
	if update_method == UpdateMethod.PHYSICS:
		_update_frame(delta, Engine.get_physics_frames())
	elif update_method == UpdateMethod.SMART and _desired_source_is_physics_driven():
		_update_frame(delta, Engine.get_physics_frames())

func manual_update(delta: float = -1.0) -> void:
	var step: float = delta if delta >= 0.0 else get_process_delta_time()
	_update_frame(step, _frame + 1)

func is_live(camera: CameramanVirtualCameraBase) -> bool:
	return _blend_manager.is_live(camera)

func get_live_description() -> String:
	if active_blend != null:
		return active_blend.description()
	if _blend_manager.active_source != null:
		return _blend_manager.active_source.get_description()
	return "<none>"

func default_world_up() -> Vector3:
	if world_up_override != null:
		return world_up_override.global_basis.y.normalized()
	return Vector3.UP

func set_camera_override(
	identifier: int,
	priority_value: int,
	camera_a: Object,
	camera_b: Object,
	weight_b: float,
	_delta: float
) -> int:
	var id: int = identifier
	if id < 0:
		id = _next_override_id
		_next_override_id += 1
	var weight: float = clampf(weight_b, 0.0, 1.0)
	var entry: Dictionary = _overrides.get(id, {})
	var blend: CameramanBlend = entry.get("blend") as CameramanBlend
	if blend == null:
		var definition: CameramanBlendDefinition = CameramanBlendDefinition.new()
		definition.style = CameramanBlendDefinition.Style.LINEAR
		definition.time = 1.0
		blend = CameramanBlend.new(camera_a, camera_b, definition)
		blend.manual_weight = true
		entry["blend"] = blend
		entry["source"] = CameramanNestedBlendSource.new(blend)
	else:
		blend.cam_a = camera_a
		blend.cam_b = camera_b
	blend.time_in_blend = weight
	entry["priority"] = priority_value
	entry["camera_a"] = camera_a
	entry["camera_b"] = camera_b
	entry["weight_b"] = weight
	_overrides[id] = entry
	return id

func release_camera_override(identifier: int) -> void:
	_overrides.erase(identifier)

func get_output_camera() -> Camera3D:
	if not camera_path.is_empty():
		return get_node_or_null(camera_path) as Camera3D
	return get_parent() as Camera3D

func get_blend_definition(
	from_source: Object,
	to_source: Object,
	fallback: CameramanBlendDefinition
) -> CameramanBlendDefinition:
	if CameramanCore.get_blend_override.is_valid():
		var override_value: Object = CameramanCore.get_blend_override.call(
			from_source,
			to_source,
			fallback,
			self
		) as Object
		if override_value is CameramanBlendDefinition:
			return override_value as CameramanBlendDefinition
	if custom_blends != null:
		return custom_blends.get_blend_for(
			from_source.get_camera_name(),
			to_source.get_camera_name(),
			fallback
		)
	return fallback

func _update_frame(raw_delta: float, clock_frame: int) -> void:
	_frame += 1
	_update_token = clock_frame
	var delta: float = CameramanCore.delta_time(raw_delta)
	if ignore_time_scale and Engine.time_scale != 0.0:
		delta /= Engine.time_scale
	var world_up: Vector3 = default_world_up()
	_update_aspect_ratio()
	var desired: Object = _get_desired_source()
	if desired == null:
		return
	var outgoing: Object = _blend_manager.active_source
	var changed: bool = _blend_manager.update_root_frame(desired, world_up, delta, default_blend, self)
	if changed and desired is CameramanVirtualCameraBase:
		active_virtual_camera = desired as CameramanVirtualCameraBase
		camera_activated.emit(self, desired, outgoing)
		if _live_camera != active_virtual_camera:
			CameramanCore.set_camera_live(_live_camera, false)
			_live_camera = active_virtual_camera
			CameramanCore.set_camera_live(_live_camera, true)
		if _blend_manager.active_blend == null:
			camera_cut.emit(self)
	current_camera_state = _blend_manager.update(world_up, delta, Callable(self, "_update_camera"))
	_apply_state(current_camera_state)
	_update_debug_frustum(current_camera_state)
	_update_standby_cameras(world_up, delta)
	CameramanCore.get_events().camera_updated.emit(self)
	_update_debug_text()

func _get_desired_source() -> Object:
	var override_entry: Dictionary = _get_top_override()
	if not override_entry.is_empty():
		var camera_a: Object = override_entry["camera_a"] as Object
		var camera_b: Object = override_entry["camera_b"] as Object
		var weight_b: float = float(override_entry["weight_b"])
		if camera_b == null:
			return camera_a
		if weight_b >= 1.0:
			return camera_b
		if camera_a == null:
			return camera_b
		return override_entry["source"] as CameramanNestedBlendSource
	if CameramanCore.solo_camera != null:
		return CameramanCore.solo_camera
	return CameramanCore.get_registry().get_top_camera(channel_mask, self)

func _get_top_override() -> Dictionary:
	var selected: Dictionary = {}
	var selected_priority: int = -2147483648
	for entry in _overrides.values():
		if int(entry["priority"]) > selected_priority:
			selected = entry
			selected_priority = int(entry["priority"])
	return selected

func _apply_state(state: CameramanCameraState) -> void:
	var output: Camera3D = get_output_camera()
	if output == null:
		return
	var orientation: Quaternion = state.get_final_orientation()
	var dutch: float = deg_to_rad(state.lens.dutch_degrees)
	var basis: Basis = Basis(orientation).rotated(Vector3.FORWARD, dutch)
	output.global_transform = Transform3D(basis, state.get_final_position())
	output.keep_aspect = Camera3D.KEEP_HEIGHT
	output.near = state.lens.near
	output.far = state.lens.far
	var mode: CameramanLens.Mode = state.lens.mode_override
	if lens_mode_override_enabled:
		mode = default_lens_mode
	if mode == CameramanLens.Mode.ORTHOGRAPHIC:
		output.projection = Camera3D.PROJECTION_ORTHOGONAL
		output.size = state.lens.orthographic_size * 2.0
	elif mode == CameramanLens.Mode.FRUSTUM:
		output.projection = Camera3D.PROJECTION_FRUSTUM
		output.fov = state.lens.fov_degrees
		output.frustum_offset = state.lens.frustum_offset
	else:
		output.projection = Camera3D.PROJECTION_PERSPECTIVE
		output.fov = state.lens.fov_degrees

func _update_camera(camera: Node3D, world_up: Vector3, delta: float) -> void:
	CameramanCore.update_virtual_camera(camera, world_up, delta, _update_token)

func _update_aspect_ratio() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.y > 0.0:
		CameramanCameraState.aspect_ratio = viewport_size.x / viewport_size.y

func _record_target_transforms(physics: bool) -> void:
	for camera in CameramanCore.get_registry().get_cameras():
		var target: Node3D = camera.call("get_follow") as Node3D
		if physics:
			_update_tracker.record_physics(target)
		else:
			_update_tracker.record_process(target)

func _desired_source_is_physics_driven() -> bool:
	var source: Object = _get_desired_source()
	if source is CameramanVirtualCameraBase:
		return _update_tracker.is_physics_driven(source.get_follow())
	if source is CameramanNestedBlendSource and source.blend.cam_b is CameramanVirtualCameraBase:
		return _update_tracker.is_physics_driven(source.blend.cam_b.get_follow())
	return false

func _update_standby_cameras(world_up: Vector3, delta: float) -> void:
	if _blend_manager.active_source == null:
		return
	var always: Array[Node3D] = []
	var round_robin: Array[Node3D] = []
	for camera in CameramanCore.get_registry().get_cameras():
		if _blend_manager.is_live(camera):
			continue
		var virtual_camera: CameramanVirtualCameraBase = camera as CameramanVirtualCameraBase
		if virtual_camera == null or (virtual_camera.output_channel & channel_mask) == 0:
			continue
		var parent_mixer: Node = virtual_camera.get_parent_mixer()
		if parent_mixer != null and parent_mixer != self:
			continue
		if virtual_camera.standby_update == CameramanVirtualCameraBase.StandbyUpdate.ALWAYS:
			always.append(camera)
		elif virtual_camera.standby_update == CameramanVirtualCameraBase.StandbyUpdate.ROUND_ROBIN:
			round_robin.append(camera)
	for camera in always:
		_update_camera(camera, world_up, delta)
	if not round_robin.is_empty():
		var camera: Node3D = round_robin[_standby_index % round_robin.size()]
		_standby_index += 1
		_update_camera(camera, world_up, delta)

func _update_debug_text() -> void:
	if not show_debug_text:
		if _debug_label != null:
			_debug_label.queue_free()
			_debug_label = null
		if _debug_layer != null:
			_debug_layer.queue_free()
			_debug_layer = null
		return
	if _debug_label == null:
		_debug_layer = CanvasLayer.new()
		_debug_layer.layer = 100
		add_child(_debug_layer)
		_debug_label = Label.new()
		_debug_label.position = Vector2(12.0, 12.0)
		_debug_layer.add_child(_debug_label)
	_debug_label.text = "Camera: %s" % get_live_description()

func _update_debug_frustum(state: CameramanCameraState) -> void:
	var output: Camera3D = get_output_camera()
	if output == null or not show_camera_frustum:
		if _frustum_instance != null:
			_frustum_instance.queue_free()
			_frustum_instance = null
			_frustum_mesh = null
		return
	if _frustum_instance != null:
		return
	_frustum_mesh = ImmediateMesh.new()
	_frustum_instance = MeshInstance3D.new()
	_frustum_instance.name = "CameramanFrustumDebug"
	_frustum_instance.mesh = _frustum_mesh
	output.add_child(_frustum_instance)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.2, 0.8, 1.0, 0.7)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_frustum_instance.material_override = material
	_frustum_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var near_distance: float = state.lens.near
	var far_distance: float = minf(state.lens.far, 100.0)
	var near_half_height: float = tan(deg_to_rad(state.lens.fov_degrees) * 0.5) * near_distance
	var far_half_height: float = tan(deg_to_rad(state.lens.fov_degrees) * 0.5) * far_distance
	var near_half_width: float = near_half_height * CameramanCameraState.aspect_ratio
	var far_half_width: float = far_half_height * CameramanCameraState.aspect_ratio
	var near_points: Array[Vector3] = _frustum_points(near_distance, near_half_width, near_half_height)
	var far_points: Array[Vector3] = _frustum_points(far_distance, far_half_width, far_half_height)
	for index in range(4):
		_add_debug_line(near_points[index], near_points[(index + 1) % 4])
		_add_debug_line(far_points[index], far_points[(index + 1) % 4])
		_add_debug_line(near_points[index], far_points[index])
	_frustum_mesh.surface_end()

func _frustum_points(depth: float, half_width: float, half_height: float) -> Array[Vector3]:
	return [
		Vector3(-half_width, -half_height, -depth),
		Vector3(half_width, -half_height, -depth),
		Vector3(half_width, half_height, -depth),
		Vector3(-half_width, half_height, -depth)
	]

func _add_debug_line(start: Vector3, end: Vector3) -> void:
	_frustum_mesh.surface_set_color(Color.WHITE)
	_frustum_mesh.surface_add_vertex(start)
	_frustum_mesh.surface_add_vertex(end)
