@tool
class_name CameramanLensPhysicalProperties
## Provides the lens physical properties configuration resource.
## Key properties include `sensor_size`, `iso`, `shutter_speed`, and related settings, which configure its behavior.
extends Resource

## Sets the sensor size used by this type.
@export var sensor_size: Vector2 = Vector2(36.0, 24.0)
## Configures the iso used by this type.
@export var iso: float = 100.0
## Configures the shutter speed used by this type.
@export var shutter_speed: float = 0.01
## Configures the aperture used by this type.
@export var aperture: float = 2.8
## Configures the blade count used by this type.
@export var blade_count: int = 5
## Configures the curvature used by this type.
@export var curvature: float = 0.0
## Configures the barrel clipping used by this type.
@export var barrel_clipping: float = 0.0
## Configures the anamorphism used by this type.
@export var anamorphism: float = 0.0
## Configures the lens shift used by this type.
@export var lens_shift: Vector2 = Vector2.ZERO
## Configures the gate fit used by this type.
@export var gate_fit: int = 0

## Returns an interpolated copy using the supplied weight.
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
