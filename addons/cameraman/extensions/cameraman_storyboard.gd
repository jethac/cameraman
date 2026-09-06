class_name CameramanStoryboard
extends CameramanExtension

enum Aspect { BEST_FIT, CROP_IMAGE_TO_FIT, STRETCH_TO_FIT }
enum RenderMode { SCREEN_SPACE_OVERLAY, SCREEN_SPACE_CAMERA, WORLD_SPACE }

@export var image: Texture2D
@export var alpha: float = 1.0
@export var show_image: bool = true
@export var aspect: Aspect = Aspect.BEST_FIT
@export var center: Vector2 = Vector2(0.5, 0.5)
@export var rotation: float = 0.0
@export var scale: Vector2 = Vector2.ONE
@export var sync_scale: bool = false
@export var mute_camera: bool = false
@export_range(0.0, 1.0) var split_view: float = 1.0
@export var render_mode: RenderMode = RenderMode.SCREEN_SPACE_OVERLAY

var _layer: CanvasLayer
var _texture_rect: TextureRect

func _process(_delta: float) -> void:
	var camera: Node = get_parent()
	if camera == null:
		return
	if _layer == null:
		_create_overlay()
	var visible_now: bool = show_image and CameramanCore.is_live(camera)
	_texture_rect.visible = visible_now
	if visible_now:
		_texture_rect.texture = image
		_texture_rect.modulate.a = alpha

func on_camera_activated(_camera: Node, _from: Object) -> void:
	if _texture_rect == null:
		_create_overlay()
	if _texture_rect != null:
		_texture_rect.visible = show_image

func on_camera_deactivated(_camera: Node, _to: Object) -> void:
	if _texture_rect != null:
		_texture_rect.visible = false

func _create_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_texture_rect = TextureRect.new()
	_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_texture_rect.position = -center * 100.0
	_texture_rect.rotation = deg_to_rad(rotation)
	_texture_rect.scale = scale
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_layer.add_child(_texture_rect)
