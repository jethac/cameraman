@tool
class_name CameramanNoiseParams
## Provides the noise params configuration resource.
## Key properties include `frequency`, `amplitude`, `constant`, which configure its behavior.
extends Resource

## Configures the frequency used by this type.
@export var frequency: float = 1.0
## Configures the amplitude used by this type.
@export var amplitude: float = 0.0
## Configures the constant used by this type.
@export var constant: bool = false
