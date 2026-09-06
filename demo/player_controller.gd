class_name CameramanDemoPlayerController
extends CharacterBody3D

@export var speed: float = 5.0
@export var acceleration: float = 12.0
@export var jump_velocity: float = 6.0
@export var mouse_sensitivity: float = 0.003
@export var mouse_look_enabled: bool = true

var _pitch: float = 0.0
var _move_basis_latched: bool = false
var _move_forward: Vector3 = Vector3.FORWARD
var _move_right: Vector3 = Vector3.RIGHT

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
	if input_vector.length_squared() > 0.001:
		if not _move_basis_latched:
			_latch_move_basis(camera)
	else:
		_move_basis_latched = false
	var forward: Vector3 = _move_forward if _move_basis_latched else -global_basis.z
	var right: Vector3 = _move_right if _move_basis_latched else global_basis.x
	var move_direction: Vector3 = (right * input_vector.x - forward * input_vector.y).normalized()
	var target_velocity: Vector3 = move_direction * speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	if move_direction.length_squared() > 0.001 and not mouse_look_enabled:
		rotation.y = lerp_angle(rotation.y, atan2(-move_direction.x, -move_direction.z), delta * 8.0)
	move_and_slide()

func _latch_move_basis(camera: Camera3D) -> void:
	var forward: Vector3 = -global_basis.z
	var right: Vector3 = global_basis.x
	if camera != null:
		forward = -camera.global_basis.z
		right = camera.global_basis.x
	forward.y = 0.0
	right.y = 0.0
	_move_forward = forward.normalized()
	_move_right = right.normalized()
	_move_basis_latched = true

func _unhandled_input(event: InputEvent) -> void:
	if not mouse_look_enabled:
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion == null:
		return
	rotation.y -= motion.relative.x * mouse_sensitivity
	_pitch = clampf(_pitch - motion.relative.y * mouse_sensitivity, -1.0, 1.0)
	var pivot: Node3D = get_node_or_null("PitchPivot") as Node3D
	if pivot != null:
		pivot.rotation.x = _pitch
