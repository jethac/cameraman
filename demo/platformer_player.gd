class_name CameramanDemoPlatformerPlayer
extends CharacterBody2D

@export var speed: float = 320.0
@export var jump_velocity: float = 420.0
var camera_target: CameramanCamera

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += 980.0 * delta
	elif Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept"):
		velocity.y = -jump_velocity
	var axis: float = Input.get_axis("move_left", "move_right")
	velocity.x = move_toward(velocity.x, axis * speed, 1600.0 * delta)
	move_and_slide()
	if camera_target != null:
		camera_target.position = Vector3(global_position.x, global_position.y, 0.0)
