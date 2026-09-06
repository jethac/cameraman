@tool
class_name CameramanLensPhysicalProperties
extends Resource

@export var sensor_size: Vector2 = Vector2(36.0, 24.0)
@export var iso: float = 100.0
@export var shutter_speed: float = 0.01
@export var aperture: float = 2.8
@export var blade_count: int = 5
@export var curvature: float = 0.0
@export var barrel_clipping: float = 0.0
@export var anamorphism: float = 0.0
@export var lens_shift: Vector2 = Vector2.ZERO
@export var gate_fit: int = 0

func lerp(other: CameramanLensPhysicalProperties, weight: float) -> CameramanLensPhysicalProperties:
	var result: CameramanLensPhysicalProperties = duplicate() as CameramanLensPhysicalProperties
	result.sensor_size = sensor_size.lerp(other.sensor_size, weight)
	result.iso = lerpf(iso, other.iso, weight)
	result.shutter_speed = lerpf(shutter_speed, other.shutter_speed, weight)
	result.aperture = lerpf(aperture, other.aperture, weight)
	result.blade_count = other.blade_count if weight > 0.5 else blade_count
	result.curvature = lerpf(curvature, other.curvature, weight)
	result.barrel_clipping = lerpf(barrel_clipping, other.barrel_clipping, weight)
	result.anamorphism = lerpf(anamorphism, other.anamorphism, weight)
	result.lens_shift = lens_shift.lerp(other.lens_shift, weight)
	result.gate_fit = other.gate_fit if weight > 0.5 else gate_fit
	return result
