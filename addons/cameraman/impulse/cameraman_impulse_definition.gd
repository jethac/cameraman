class_name CameramanImpulseDefinition
extends Resource

enum Shape { RECOIL, BUMP, EXPLOSION, RUMBLE, CUSTOM }
enum ImpulseType { UNIFORM, DISSIPATING, PROPAGATING, LEGACY }

@export_flags_3d_physics var impulse_channel: int = 1
@export var impulse_shape: Shape = Shape.BUMP
@export var custom_shape: Curve
@export var impulse_duration: float = 0.5
@export var impulse_type: ImpulseType = ImpulseType.UNIFORM
@export var dissipation_rate: float = 1.0
@export var dissipation_distance: float = 0.0
@export var propagation_speed: float = 0.0
@export var amplitude_gain: float = 1.0
@export var frequency_gain: float = 1.0

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
