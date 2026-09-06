class_name CameramanCollisionImpulseSource
extends CameramanImpulseSource

@export_flags_3d_physics var collision_mask: int = 1
@export var ignore_group: StringName
@export var use_impact_direction: bool = true
@export var scale_impact_with_mass: bool = false
@export var scale_impact_with_speed: bool = false

func _ready() -> void:
	var parent_node: Node = get_parent()
	if parent_node is RigidBody3D and (parent_node as RigidBody3D).body_entered.is_connected(_on_body_entered) == false:
		(parent_node as RigidBody3D).body_entered.connect(_on_body_entered)
	elif parent_node is Area3D and (parent_node as Area3D).body_entered.is_connected(_on_body_entered) == false:
		(parent_node as Area3D).body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body == null or (not ignore_group.is_empty() and body.is_in_group(ignore_group)):
		return
	var velocity: Vector3 = default_velocity
	if use_impact_direction:
		velocity = (global_position - body.global_position).normalized() * maxf(velocity.length(), 1.0)
	generate_impulse_at(global_position, velocity)
