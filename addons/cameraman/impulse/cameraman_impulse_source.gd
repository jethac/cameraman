@tool
class_name CameramanImpulseSource
## Scene node that creates impulse events from a configured definition.
extends Node3D

## Definition cloned when this source creates an impulse event.
@export var impulse_definition: CameramanImpulseDefinition
## Velocity used by generate_impulse when no explicit velocity is supplied.
@export var default_velocity: Vector3 = Vector3.ZERO

## Generates an event at the source using default_velocity.
func generate_impulse() -> CameramanImpulseEvent:
	return generate_impulse_at(global_position, default_velocity)

## Generates an event at the source using the supplied velocity.
func generate_impulse_with_velocity(velocity: Vector3) -> CameramanImpulseEvent:
	return generate_impulse_at(global_position, velocity)

## Generates an event at position using the supplied velocity.
func generate_impulse_at(position: Vector3, velocity: Vector3) -> CameramanImpulseEvent:
	if impulse_definition == null:
		return null
	var event: CameramanImpulseEvent = impulse_definition.create_event(velocity, position)
	var manager: CameramanImpulseManager = CameramanCore.get_impulse_manager()
	event.start_time = manager.get_time()
	event.ignore_time_scale = manager.ignore_time_scale
	manager.add_impulse_event(event)
	return event

## Generates an event using force converted to source impulse velocity.
func generate_impulse_with_force(force: Vector3) -> CameramanImpulseEvent:
	return generate_impulse_with_velocity(force)
