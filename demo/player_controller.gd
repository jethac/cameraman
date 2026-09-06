class_name CameramanDemoPlayerController
extends CharacterBody3D

@export var speed: float = 5.0

func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	velocity.x = direction.x * speed
	velocity.z = direction.y * speed
	move_and_slide()
