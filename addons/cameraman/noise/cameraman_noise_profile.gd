@tool
class_name CameramanNoiseProfile
## Provides the noise profile configuration resource.
## Key properties include `position_noise`, `orientation_noise`, which configure its behavior.
extends Resource

## Configures the position noise used by this type.
@export var position_noise: Array[CameramanNoiseChannel] = []
## Configures the orientation noise used by this type.
@export var orientation_noise: Array[CameramanNoiseChannel] = []

var _seed: int = 1

## Evaluates the position.
func evaluate_position(time_value: float) -> Vector3:
	return _evaluate_channels(position_noise, time_value)

## Evaluates the orientation.
func evaluate_orientation(time_value: float) -> Vector3:
	return _evaluate_channels(orientation_noise, time_value)

## Reseeds the noise generators.
func reseed(seed_value: int = -1) -> void:
	_seed = seed_value if seed_value >= 0 else randi()

func _evaluate_channels(channels: Array[CameramanNoiseChannel], time_value: float) -> Vector3:
	var result: Vector3 = Vector3.ZERO
	for index in channels.size():
		var channel: CameramanNoiseChannel = channels[index]
		if channel == null:
			continue
		result.x += _evaluate(channel.x, time_value, index * 3)
		result.y += _evaluate(channel.y, time_value, index * 3 + 1)
		result.z += _evaluate(channel.z, time_value, index * 3 + 2)
	return result

func _evaluate(params: CameramanNoiseParams, time_value: float, axis_seed: int) -> float:
	if params == null or params.amplitude == 0.0:
		return 0.0
	var phase: float = time_value * params.frequency + float(_seed + axis_seed) * 0.137
	if params.constant:
		return sin(phase) * params.amplitude
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = _seed + axis_seed
	noise.frequency = maxf(params.frequency, 0.001)
	return noise.get_noise_1d(time_value) * params.amplitude
