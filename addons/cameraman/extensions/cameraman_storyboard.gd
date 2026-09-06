@tool
class_name CameramanStoryboard
## Camera lifecycle extension that renders a texture in overlay, camera-space, or world-space
## mode.
extends CameramanExtension

enum Aspect { BEST_FIT, CROP_IMAGE_TO_FIT, STRETCH_TO_FIT }
enum RenderMode { SCREEN_SPACE_OVERLAY, SCREEN_SPACE_CAMERA, WORLD_SPACE }

## Texture rendered by the storyboard layer.
@export var image: Texture2D
## Opacity multiplier applied to the storyboard texture.
@export var alpha: float = 1.0
## Creates and displays the storyboard layer when enabled.
@export var show_image: bool = true
## Selects how the texture fits or fills its render area.
@export var aspect: Aspect = Aspect.BEST_FIT
## Normalized texture center position within the render area.
@export var center: Vector2 = Vector2(0.5, 0.5)
## Texture rotation in degrees around its center.
@export var rotation: float = 0.0
## Local texture scale applied after aspect fitting.
@export var scale: Vector2 = Vector2.ONE
## Couples texture scale to the output camera scale when enabled.
@export var sync_scale: bool = false
## Hides the camera image while the storyboard layer is active.
@export var mute_camera: bool = false
## Fraction of the viewport width occupied by the storyboard view.
@export_range(0.0, 1.0) var split_view: float = 1.0
## Selects overlay, camera-space, or world-space rendering.
@export var render_mode: RenderMode = RenderMode.SCREEN_SPACE_OVERLAY
## Distance in meters from the output camera for world-space rendering.
@export var world_distance: float = 1.0
## Set a distinct layer per output camera and match its cull_mask when several brains share a world.
@export_flags_3d_render var world_render_layers: int = 1

var _active_mode: int = -1
var _layer: CanvasLayer
var _screen_container: Control
var _texture_rect: TextureRect
var _world_quad: MeshInstance3D
var _world_material: StandardMaterial3D

func _ready() -> void:
	var brain: Node = CameramanCore.find_brain_for(get_parent())
	process_priority = brain.process_priority + 1 if brain != null else 1001

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var camera: Node = get_parent()
	if camera == null:
		return
	_ensure_mode()
	var brain: Node = CameramanCore.find_brain_for(camera)
	var visible_now: bool = show_image and _camera_is_live(camera, brain)
	camera.set_meta("cameraman_mute_camera", mute_camera and visible_now)
	if render_mode == RenderMode.WORLD_SPACE:
		_update_world_space(camera, brain, visible_now)
	else:
		_update_screen_space(brain, visible_now)

func on_camera_activated(_camera: Node, _from: Object) -> void:
	_ensure_mode()
	if _texture_rect != null:
		_texture_rect.visible = show_image
	if _world_quad != null:
		_world_quad.visible = show_image

func on_camera_deactivated(_camera: Node, _to: Object) -> void:
	if _texture_rect != null:
		_texture_rect.visible = false
	if _world_quad != null:
		_world_quad.visible = false

func _ensure_mode() -> void:
	if _active_mode == render_mode:
		return
	_teardown_render_nodes()
	_active_mode = render_mode
	if render_mode == RenderMode.WORLD_SPACE:
		_create_world_space()
	else:
		_create_screen_space()

func _teardown_render_nodes() -> void:
	if _layer != null:
		var root_viewport: Viewport = get_viewport()
		if root_viewport != null and _layer.get_viewport() != root_viewport:
			_layer.custom_viewport = root_viewport
		remove_child(_layer)
		_layer.free()
	_layer = null
	_screen_container = null
	_texture_rect = null
	if _world_quad != null:
		remove_child(_world_quad)
		_world_quad.free()
	_world_quad = null
	_world_material = null

func _create_screen_space() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100 if render_mode == RenderMode.SCREEN_SPACE_OVERLAY else 1
	add_child(_layer)
	_screen_container = Control.new()
	_screen_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_screen_container.clip_contents = true
	_layer.add_child(_screen_container)
	_texture_rect = TextureRect.new()
	_texture_rect.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_screen_container.add_child(_texture_rect)

func _create_world_space() -> void:
	_world_quad = MeshInstance3D.new()
	_world_quad.layers = world_render_layers
	var quad: QuadMesh = QuadMesh.new()
	_world_quad.mesh = quad
	_world_material = StandardMaterial3D.new()
	_world_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_world_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_world_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_world_material.no_depth_test = false
	_world_quad.material_override = _world_material
	add_child(_world_quad)

func _update_screen_space(brain: Node, visible_now: bool) -> void:
	if _texture_rect == null or _screen_container == null:
		return
	var output: Camera3D
	if brain != null and brain.has_method("get_output_camera"):
		output = brain.call("get_output_camera") as Camera3D
	var output_viewport: Viewport
	if brain != null and brain.has_method("get_output_viewport"):
		output_viewport = brain.call("get_output_viewport") as Viewport
	if render_mode == RenderMode.SCREEN_SPACE_CAMERA:
		if output_viewport != null and output_viewport != _layer.get_viewport():
			_layer.custom_viewport = output_viewport
	var viewport_size: Vector2 = (
		_viewport_size_of(output_viewport)
		if render_mode == RenderMode.SCREEN_SPACE_CAMERA
		else _viewport_size_of(get_viewport())
	)
	var split: float = clampf(split_view, 0.0, 1.0)
	_screen_container.position = Vector2.ZERO
	_screen_container.size = Vector2(viewport_size.x * split, viewport_size.y)
	_texture_rect.position = (center - Vector2(0.5, 0.5)) * viewport_size
	_texture_rect.size = viewport_size
	_texture_rect.pivot_offset = viewport_size * 0.5
	_texture_rect.texture = image
	_texture_rect.modulate = Color(1.0, 1.0, 1.0, alpha)
	_texture_rect.rotation = deg_to_rad(rotation)
	_texture_rect.scale = scale
	if sync_scale and image != null:
		var image_size: Vector2 = image.get_size()
		if image_size.x > 0.0 and image_size.y > 0.0:
			_texture_rect.scale *= viewport_size / image_size
	match aspect:
		Aspect.CROP_IMAGE_TO_FIT:
			_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		Aspect.STRETCH_TO_FIT:
			_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
		_:
			_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_texture_rect.visible = visible_now and image != null

func _update_world_space(_camera: Node, brain: Node, visible_now: bool) -> void:
	if _world_quad == null:
		return
	_world_quad.layers = world_render_layers
	var output: Camera3D
	if brain != null and brain.has_method("get_output_camera"):
		output = brain.call("get_output_camera") as Camera3D
	if output == null or image == null or not visible_now:
		_world_quad.visible = false
		return
	var distance: float = _effective_world_distance(output)
	var viewport_size: Vector2 = _viewport_size(output)
	var aspect_ratio: float = viewport_size.x / maxf(viewport_size.y, 1.0)
	var frame_size: Vector2 = _get_frustum_size(output, aspect_ratio, distance)
	var image_size: Vector2 = image.get_size()
	var image_aspect: float = image_size.x / maxf(image_size.y, 1.0)
	var display_size: Vector2 = frame_size
	var uv_scale: Vector3 = Vector3.ONE
	var uv_offset: Vector3 = Vector3.ZERO
	match aspect:
		Aspect.BEST_FIT:
			if image_aspect > frame_size.x / maxf(frame_size.y, 0.001):
				display_size.y = frame_size.x / image_aspect
			else:
				display_size.x = frame_size.y * image_aspect
		Aspect.CROP_IMAGE_TO_FIT:
			var frame_aspect: float = frame_size.x / maxf(frame_size.y, 0.001)
			if image_aspect > frame_aspect:
				var visible_width: float = frame_aspect / image_aspect
				uv_scale.x = visible_width
				uv_offset.x = (1.0 - visible_width) * 0.5
			else:
				var visible_height: float = image_aspect / frame_aspect
				uv_scale.y = visible_height
				uv_offset.y = (1.0 - visible_height) * 0.5
	_world_material.albedo_texture = image
	_world_material.albedo_color = Color(1.0, 1.0, 1.0, alpha)
	_world_material.uv1_scale = uv_scale
	_world_material.uv1_offset = uv_offset
	(_world_quad.mesh as QuadMesh).size = display_size
	_world_quad.scale = Vector3(scale.x, scale.y, 1.0)
	var view_basis: Basis = output.global_basis.orthonormalized()
	var view_axis: Vector3 = view_basis.z.normalized()
	_world_quad.global_basis = Basis(Quaternion(view_axis, deg_to_rad(rotation))) * view_basis
	var forward: Vector3 = -view_basis.z
	var center_offset: Vector2 = (center - Vector2(0.5, 0.5)) * frame_size
	center_offset += _get_frustum_shift(output, distance)
	_world_quad.global_position = (
		output.global_position
		+ forward * distance
		+ view_basis.x * center_offset.x
		+ view_basis.y * center_offset.y
	)
	_world_quad.visible = true

func _effective_world_distance(output: Camera3D) -> float:
	return clampf(world_distance, output.near * 1.01 + 0.001, output.far * 0.99)

func _get_frustum_size(output: Camera3D, aspect_ratio: float, distance: float) -> Vector2:
	if output.projection == Camera3D.PROJECTION_ORTHOGONAL:
		return Vector2(output.size * aspect_ratio, output.size)
	if output.projection == Camera3D.PROJECTION_FRUSTUM:
		var scale_factor: float = distance / maxf(output.near, 0.001)
		return Vector2(output.size * aspect_ratio, output.size) * scale_factor
	var height: float = 2.0 * distance * tan(deg_to_rad(output.fov) * 0.5)
	return Vector2(height * aspect_ratio, height)

func _get_frustum_shift(output: Camera3D, distance: float) -> Vector2:
	if output.projection != Camera3D.PROJECTION_FRUSTUM:
		return Vector2.ZERO
	var scale_factor: float = distance / maxf(output.near, 0.001)
	return output.frustum_offset * scale_factor

func _camera_is_live(camera: Node, brain: Node) -> bool:
	if brain != null:
		return CameramanCore.is_live_in_brain(brain, camera)
	return CameramanCore.is_live(camera as Node3D)

func _viewport_size(output: Camera3D = null) -> Vector2:
	return _viewport_size_of(output.get_viewport() if output != null else null)

func _viewport_size_of(viewport: Viewport = null) -> Vector2:
	if viewport == null:
		viewport = get_viewport()
	if viewport != null:
		var size: Vector2 = viewport.get_visible_rect().size
		if size.x > 0.0 and size.y > 0.0:
			return size
	var height: float = 1.0
	return Vector2(CameramanCameraState.aspect_ratio * height, height)
