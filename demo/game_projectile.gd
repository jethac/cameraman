class_name CameramanDemoProjectile
extends RigidBody3D

var lifetime: float = 4.0
var _hit_registered: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	contact_monitor = true
	max_contacts_reported = 8
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
	var hit_area: Area3D = Area3D.new()
	hit_area.collision_layer = 0
	hit_area.collision_mask = 1
	var hit_area_shape: CollisionShape3D = CollisionShape3D.new()
	var hit_area_sphere: SphereShape3D = SphereShape3D.new()
	hit_area_sphere.radius = 0.2
	hit_area_shape.shape = hit_area_sphere
	hit_area.add_child(hit_area_shape)
	add_child(hit_area)
	hit_area.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body == self:
		return
	if not _hit_registered and body is CameramanDemoEnemy:
		_hit_registered = true
		(body as CameramanDemoEnemy).take_projectile_hit(global_position)
		queue_free()
