@tool
class_name CameramanNoiseProfile
## Resource containing position and orientation noise channels evaluated over time.
extends Resource

@export var position_noise: Array[CameramanNoiseChannel] = []
@export var orientation_noise: Array[CameramanNoiseChannel] = []

var _seed: int = 1

## Samples all position channels at time_value and returns a Vector3 offset.
func evaluate_position(time_value: float) -> Vector3:
	return _evaluate_channels(position_noise, time_value)

## Samples all orientation channels at time_value and returns Euler correction angles.
func evaluate_orientation(time_value: float) -> Vector3:
	return _evaluate_channels(orientation_noise, time_value)

## Reseeds every channel; seed_value -1 selects a new random seed.
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
