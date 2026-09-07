@tool
class_name CameramanImpulseDefinition
## Resource defining impulse shape, timing, propagation, dissipation, and gains.
extends Resource

enum Shape { RECOIL, BUMP, EXPLOSION, RUMBLE, CUSTOM }
enum ImpulseType { UNIFORM, DISSIPATING, PROPAGATING, LEGACY }

## Channel mask used to filter this impulse at listeners.
@export_flags_3d_physics var impulse_channel: int = 1
## Selects the envelope shape applied over impulse time.
@export var impulse_shape: Shape = Shape.BUMP
## Curve sampled when impulse_shape selects a custom envelope.
@export var custom_shape: Curve
## Duration in seconds before a non-propagating impulse expires.
@export var impulse_duration: float = 0.5
## Selects uniform or dissipating propagation behavior.
@export var impulse_type: ImpulseType = ImpulseType.UNIFORM
## Falloff per second for dissipating impulses.
@export var dissipation_rate: float = 1.0
## Distance in meters over which a dissipating impulse falls off.
@export var dissipation_distance: float = 0.0
## Meters per second at which the impulse front travels; zero disables delay.
@export var propagation_speed: float = 0.0
## Multiplies positional impulse amplitude.
@export var amplitude_gain: float = 1.0
## Multiplies rotational impulse frequency.
@export var frequency_gain: float = 1.0

## Creates an event whose velocity and origin are copied from the arguments.
func create_event(velocity: Vector3, position: Vector3) -> CameramanImpulseEvent:
	var event: CameramanImpulseEvent = CameramanImpulseEvent.new()
	event.position = position
	event.signal_velocity = velocity * amplitude_gain
	event.radius = dissipation_distance
	event.duration = impulse_duration
	event.channel = impulse_channel
	event.start_time = CameramanCore.current_time()
	event.impulse_type = impulse_type
	event.dissipation_rate = dissipation_rate
	event.dissipation_distance = dissipation_distance
	event.envelope_shape = impulse_shape
	event.custom_curve = custom_shape
	event.propagation_speed = propagation_speed
	event.envelope_curve = _make_envelope()
	event.frequency_gain = frequency_gain
	return event

func envelope(time_value: float) -> float:
	var normalized: float = clampf(time_value / maxf(impulse_duration, 0.0001), 0.0, 1.0)
	if impulse_shape == Shape.CUSTOM and custom_shape != null:
		return custom_shape.sample(normalized)
	if impulse_shape == Shape.RECOIL:
		return 1.0 - normalized
	if impulse_shape == Shape.EXPLOSION:
		return sin(normalized * PI)
	if impulse_shape == Shape.RUMBLE:
		return sin(normalized * TAU * 8.0) * (1.0 - normalized)
	return 1.0 - absf(normalized * 2.0 - 1.0)

func _make_envelope() -> Curve:
	if impulse_shape == Shape.CUSTOM:
		return custom_shape
	var curve: Curve = Curve.new()
	curve.min_value = -1.0
	curve.max_value = 1.0
	curve.add_point(Vector2(0.0, 1.0 if impulse_shape != Shape.EXPLOSION else 0.0))
	match impulse_shape:
		Shape.RECOIL:
			curve.add_point(Vector2(0.2, 1.0))
			curve.add_point(Vector2(1.0, 0.0))
		Shape.BUMP:
			curve.add_point(Vector2(0.2, 1.0))
			curve.add_point(Vector2(1.0, 0.0))
		Shape.EXPLOSION:
			curve.add_point(Vector2(0.5, 1.0))
			curve.add_point(Vector2(1.0, 0.0))
		Shape.RUMBLE:
			for index in range(1, 9):
				curve.add_point(Vector2(float(index) / 8.0, sin(float(index) * PI * 2.0) * (
					1.0 - float(index) / 8.0
				)))
		_:
			curve.add_point(Vector2(1.0, 0.0))
	return curve
