@tool
class_name CameramanNoiseParams
## Resource defining frequency, amplitude, and constant-value behavior for one noise axis.
extends Resource

## Noise cycles per second; zero produces a constant sample.
@export var frequency: float = 1.0
## Maximum signed contribution produced by this channel.
@export var amplitude: float = 0.0
## Uses a seeded constant value instead of time-varying noise.
@export var constant: bool = false
