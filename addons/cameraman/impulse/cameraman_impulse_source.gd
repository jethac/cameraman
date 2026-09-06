class_name CameramanImpulseSource
extends Node3D

@export var impulse_definition: CameramanImpulseDefinition
@export var default_velocity: Vector3 = Vector3.ZERO

func generate_impulse() -> CameramanImpulseEvent:
	return generate_impulse_at(global_position, default_velocity)

func generate_impulse_with_velocity(velocity: Vector3) -> CameramanImpulseEvent:
	return generate_impulse_at(global_position, velocity)

func generate_impulse_at(position: Vector3, velocity: Vector3) -> CameramanImpulseEvent:
	if impulse_definition == null:
		return null
	var event: CameramanImpulseEvent = impulse_definition.create_event(velocity, position)
	CameramanCore.get_impulse_manager().add_impulse_event(event)
	return event

func generate_impulse_with_force(force: Vector3) -> CameramanImpulseEvent:
	return generate_impulse_with_velocity(force)
