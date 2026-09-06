@tool
class_name CameramanImpulseSource
## Generates impulse events from configured definitions and source velocities.
## Key properties include `impulse_definition`, `default_velocity`, which configure its behavior.
extends Node3D

## Configures the impulse definition used by this type.
@export var impulse_definition: CameramanImpulseDefinition
## Configures the default velocity used by this type.
@export var default_velocity: Vector3 = Vector3.ZERO

## Generates and dispatches an impulse event.
func generate_impulse() -> CameramanImpulseEvent:
	return generate_impulse_at(global_position, default_velocity)

## Generates an impulse event using the supplied velocity.
func generate_impulse_with_velocity(velocity: Vector3) -> CameramanImpulseEvent:
	return generate_impulse_at(global_position, velocity)

## Generates an impulse event at the supplied position.
func generate_impulse_at(position: Vector3, velocity: Vector3) -> CameramanImpulseEvent:
	if impulse_definition == null:
		return null
	var event: CameramanImpulseEvent = impulse_definition.create_event(velocity, position)
	var manager: CameramanImpulseManager = CameramanCore.get_impulse_manager()
	event.start_time = manager.get_time()
	event.ignore_time_scale = manager.ignore_time_scale
	manager.add_impulse_event(event)
	return event

## Generates an impulse event from the supplied force.
func generate_impulse_with_force(force: Vector3) -> CameramanImpulseEvent:
	return generate_impulse_with_velocity(force)
