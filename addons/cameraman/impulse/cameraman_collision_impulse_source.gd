@tool
class_name CameramanCollisionImpulseSource
## Impulse source that emits events from body collisions matching its mask and group filter.
extends CameramanImpulseSource

## Physics layers whose body collisions generate impulses.
@export_flags_3d_physics var collision_mask: int = 1
## Colliding bodies in this group do not generate impulses.
@export var ignore_group: StringName
## Uses the collision normal to orient the generated impulse.
@export var use_impact_direction: bool = true
## Multiplies impulse strength by the other body mass when enabled.
@export var scale_impact_with_mass: bool = false
## Multiplies impulse strength by impact speed when enabled.
@export var scale_impact_with_speed: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var parent_node: Node = get_parent()
	if parent_node is RigidBody3D and (parent_node as RigidBody3D).body_entered.is_connected(_on_body_entered) == false:
		(parent_node as RigidBody3D).body_entered.connect(_on_body_entered)
	elif parent_node is Area3D and (parent_node as Area3D).body_entered.is_connected(_on_body_entered) == false:
		(parent_node as Area3D).body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body == null or (not ignore_group.is_empty() and body.is_in_group(ignore_group)):
		return
	if body is CollisionObject3D and (body as CollisionObject3D).collision_layer & collision_mask == 0:
		return
	var velocity: Vector3 = default_velocity
	var scale: float = 1.0
	if scale_impact_with_mass and body is RigidBody3D:
		scale *= maxf((body as RigidBody3D).mass, 0.0)
	if scale_impact_with_speed and body is RigidBody3D:
		scale *= (body as RigidBody3D).linear_velocity.length()
	if use_impact_direction:
		velocity = (global_position - body.global_position).normalized() * maxf(velocity.length(), 1.0)
	generate_impulse_at(global_position, velocity * scale)
