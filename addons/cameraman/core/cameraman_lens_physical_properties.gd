@tool
class_name CameramanLensPhysicalProperties
## Resource storing physical lens values used when interpolating camera optics.
extends Resource

## Sensor width and height in millimeters used for physical lens interpolation.
@export var sensor_size: Vector2 = Vector2(36.0, 24.0)
## Exposure ISO value stored with the lens state.
@export var iso: float = 100.0
## Exposure shutter duration in seconds.
@export var shutter_speed: float = 0.01
## Lens f-number stored for depth-of-field calculations.
@export var aperture: float = 2.8
## Number of aperture blades used by depth-of-field calculations.
@export var blade_count: int = 5
## Curvature coefficient stored for physical lens effects.
@export var curvature: float = 0.0
## Barrel clipping coefficient stored for physical lens effects.
@export var barrel_clipping: float = 0.0
## Anamorphic squeeze factor stored for physical lens effects.
@export var anamorphism: float = 0.0
## Physical lens shift stored as a normalized 2D offset.
@export var lens_shift: Vector2 = Vector2.ZERO
## Gate-fit mode stored for physical lens interpolation.
@export var gate_fit: int = 0

## Interpolates physical lens values without changing either source resource.
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
