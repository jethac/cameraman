@tool
class_name CameramanImpulseManager
## Provides the impulse manager runtime helper.
extends RefCounted

var ignore_time_scale: bool = false
var _events: Array[CameramanImpulseEvent] = []

## Returns the time.
func get_time() -> float:
	if CameramanCore.current_time_override >= 0.0:
		return CameramanCore.current_time_override
	if ignore_time_scale:
		return Time.get_ticks_usec() * 0.000001
	return Time.get_ticks_usec() * 0.000001 * Engine.time_scale

## Adds the impulse event.
func add_impulse_event(event: CameramanImpulseEvent) -> void:
	if event != null:
		_events.append(event)

## Returns the combined impulse affecting a position and channel mask.
func get_impulse_at(position: Vector3, use_2d: bool, channel_mask: int) -> Array[Variant]:
	var now: float = get_time()
	var position_signal: Vector3 = Vector3.ZERO
	var rotation_signal: Quaternion = Quaternion.IDENTITY
	for index in range(_events.size() - 1, -1, -1):
		var event: CameramanImpulseEvent = _events[index]
		if event.is_expired(now):
			_events.remove_at(index)
			continue
		if event.channel & channel_mask == 0:
			continue
		var result: Array[Variant] = event.get_decayed_signal(position, use_2d, now)
		position_signal += result[0] as Vector3
		rotation_signal = (rotation_signal * (result[1] as Quaternion)).normalized()
	return [position_signal, rotation_signal]

## Clears the stored events or state.
func clear() -> void:
	_events.clear()
