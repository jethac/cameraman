class_name CameramanDemoPlayerController
extends CharacterBody3D

@export var speed: float = 5.0
@export var acceleration: float = 12.0
@export var jump_velocity: float = 6.0
@export var mouse_sensitivity: float = 0.003

var _pitch: float = 0.0

func _physics_process(delta: float) -> void:
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept"):
		velocity.y = jump_velocity
	var input_vector: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)
	var camera: Camera3D = get_viewport().get_camera_3d()
	var forward: Vector3 = -global_basis.z
	var right: Vector3 = global_basis.x
	if camera != null:
		forward = -camera.global_basis.z
		right = camera.global_basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()
	var move_direction: Vector3 = (right * input_vector.x - forward * input_vector.y).normalized()
	var target_velocity: Vector3 = move_direction * speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	if move_direction.length_squared() > 0.001:
		rotation.y = lerp_angle(rotation.y, atan2(-move_direction.x, -move_direction.z), delta * 8.0)
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion == null:
		return
	rotation.y -= motion.relative.x * mouse_sensitivity
	_pitch = clampf(_pitch - motion.relative.y * mouse_sensitivity, -1.0, 1.0)
	var pivot: Node3D = get_node_or_null("PitchPivot") as Node3D
	if pivot != null:
		pivot.rotation.x = _pitch
