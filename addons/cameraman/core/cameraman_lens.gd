class_name CameramanLens
extends Resource

enum Mode { NONE, PERSPECTIVE, ORTHOGRAPHIC, FRUSTUM }

@export var fov_degrees: float = 60.0
@export var orthographic_size: float = 10.0
@export var near: float = 0.05
@export var far: float = 4000.0
@export var dutch_degrees: float = 0.0
@export var mode_override: Mode = Mode.NONE
@export var focus_distance: float = 10.0
@export var frustum_offset: Vector2 = Vector2.ZERO
@export var physical_properties: CameramanLensPhysicalProperties

func _init() -> void:
	physical_properties = CameramanLensPhysicalProperties.new()

static func from_focal_length(focal_length: float) -> float:
	return rad_to_deg(2.0 * atan(12.0 / maxf(focal_length, 0.001)))

static func preset_12mm() -> CameramanLens:
	return _preset(12.0)

static func preset_24mm() -> CameramanLens:
	return _preset(24.0)

static func preset_35mm() -> CameramanLens:
	return _preset(35.0)

static func preset_50mm() -> CameramanLens:
	return _preset(50.0)

static func preset_85mm() -> CameramanLens:
	return _preset(85.0)

static func preset_135mm() -> CameramanLens:
	return _preset(135.0)

static func preset_200mm() -> CameramanLens:
	return _preset(200.0)

static func _preset(focal_length: float) -> CameramanLens:
	var lens: CameramanLens = CameramanLens.new()
	lens.fov_degrees = from_focal_length(focal_length)
	return lens

func lerp(other: CameramanLens, weight: float) -> CameramanLens:
	var result: CameramanLens = duplicate() as CameramanLens
	var from_focal: float = 12.0 / tan(deg_to_rad(fov_degrees) * 0.5)
	var to_focal: float = 12.0 / tan(deg_to_rad(other.fov_degrees) * 0.5)
	var focal: float = lerpf(from_focal, to_focal, weight)
	result.fov_degrees = from_focal_length(focal)
	result.orthographic_size = lerpf(orthographic_size, other.orthographic_size, weight)
	result.near = lerpf(near, other.near, weight)
	result.far = lerpf(far, other.far, weight)
	result.dutch_degrees = lerpf(dutch_degrees, other.dutch_degrees, weight)
	result.focus_distance = lerpf(focus_distance, other.focus_distance, weight)
	result.frustum_offset = frustum_offset.lerp(other.frustum_offset, weight)
	if physical_properties != null and other.physical_properties != null:
		result.physical_properties = physical_properties.lerp(other.physical_properties, weight)
	result.mode_override = other.mode_override if weight > 0.5 else mode_override
	return result

func is_orthographic() -> bool:
	return mode_override == Mode.ORTHOGRAPHIC
