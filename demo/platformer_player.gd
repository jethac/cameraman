class_name CameramanDemoPlatformerPlayer
extends CharacterBody2D

@export var speed: float = 180.0

func _physics_process(_delta: float) -> void:
	velocity.x = Input.get_axis("move_left", "move_right") * speed
	move_and_slide()
