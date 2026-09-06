class_name CameramanDemoProjectile
extends RigidBody3D

var lifetime: float = 4.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	mesh.mesh = sphere
	mesh.material_override = CameramanDemoHelpers.material(Color("#f4d35e"))
	add_child(mesh)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var sphere_shape: SphereShape3D = SphereShape3D.new()
	sphere_shape.radius = 0.15
	collision.shape = sphere_shape
	add_child(collision)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body is CameramanDemoEnemy:
		(body as CameramanDemoEnemy).take_projectile_hit(global_position)
		queue_free()
