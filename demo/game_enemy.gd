class_name CameramanDemoEnemy
extends CharacterBody3D

@export var waypoints: Array[Vector3] = []
@export var patrol_speed: float = 3.0
@export var chase_speed: float = 4.0
@export var target: Node3D

var hit_count: int = 0
var _waypoint_index: int = 0
var _flash_time: float = 0.0
var _stomp_time: float = 0.0
var _mesh: MeshInstance3D
var _stomp_source: CameramanImpulseSource
var _orange_material: StandardMaterial3D

func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 1
	collision_mask = 1
	var collision: CollisionShape3D = CollisionShape3D.new()
	var capsule_shape: CapsuleShape3D = CapsuleShape3D.new()
	capsule_shape.radius = 0.5
	capsule_shape.height = 2.0
	collision.shape = capsule_shape
	add_child(collision)
	_mesh = MeshInstance3D.new()
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = 0.5
	capsule.height = 2.0
	_mesh.mesh = capsule
	_orange_material = CameramanDemoHelpers.material(Color("#ef8d32"))
	_mesh.material_override = _orange_material
	add_child(_mesh)
	var definition: CameramanImpulseDefinition = CameramanImpulseDefinition.new()
	definition.impulse_shape = CameramanImpulseDefinition.Shape.BUMP
	definition.impulse_type = CameramanImpulseDefinition.ImpulseType.DISSIPATING
	definition.dissipation_distance = 15.0
	definition.amplitude_gain = 0.6
	definition.impulse_duration = 0.45
	_stomp_source = CameramanImpulseSource.new()
	_stomp_source.impulse_definition = definition
	_stomp_source.default_velocity = Vector3.UP
	add_child(_stomp_source)

func _physics_process(delta: float) -> void:
	if target == null:
		return
	var to_target: Vector3 = target.global_position - global_position
	to_target.y = 0.0
	var chasing: bool = to_target.length() <= 8.0
	var desired: Vector3 = to_target.normalized() if chasing else _patrol_direction()
	var speed: float = chase_speed if chasing else patrol_speed
	velocity.x = move_toward(velocity.x, desired.x * speed, 10.0 * delta)
	velocity.z = move_toward(velocity.z, desired.z * speed, 10.0 * delta)
	if desired.length_squared() > 0.001:
		rotation.y = lerp_angle(rotation.y, atan2(-desired.x, -desired.z), delta * 6.0)
	move_and_slide()
	_stomp_time -= delta
	if chasing and _stomp_time <= 0.0:
		_stomp_source.generate_impulse()
		_stomp_time = 1.5

func _process(delta: float) -> void:
	if _flash_time > 0.0:
		_flash_time -= delta
		_orange_material.albedo_color = Color.WHITE
	else:
		_orange_material.albedo_color = Color("#ef8d32")

func take_projectile_hit(origin: Vector3) -> void:
	hit_count += 1
	_flash_time = 0.2
	var away: Vector3 = (global_position - origin).normalized()
	velocity += away * 2.0
	if hit_count >= 3:
		queue_free()

func _patrol_direction() -> Vector3:
	if waypoints.is_empty():
		return Vector3.ZERO
	var destination: Vector3 = waypoints[_waypoint_index]
	var direction: Vector3 = destination - global_position
	direction.y = 0.0
	if direction.length() < 0.8:
		_waypoint_index = (_waypoint_index + 1) % waypoints.size()
		destination = waypoints[_waypoint_index]
		direction = destination - global_position
		direction.y = 0.0
	return direction.normalized()
