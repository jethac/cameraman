class_name CameramanDemoHelpers
extends RefCounted

static func material(color: Color) -> StandardMaterial3D:
	var result: StandardMaterial3D = StandardMaterial3D.new()
	result.albedo_color = color
	return result

static func add_environment(parent: Node3D) -> void:
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	light.shadow_enabled = true
	light.light_energy = 1.2
	parent.add_child(light)
	var environment: WorldEnvironment = WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	var sky: Sky = Sky.new()
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#18355c")
	sky_material.sky_horizon_color = Color("#8fc4dd")
	sky_material.ground_bottom_color = Color("#18202b")
	sky_material.ground_horizon_color = Color("#718b9a")
	sky.sky_material = sky_material
	environment.environment = Environment.new()
	environment.environment.sky = sky
	environment.environment.background_mode = Environment.BG_SKY
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.environment.ambient_light_energy = 0.7
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	parent.add_child(environment)

static func create_player(parent: Node3D, position: Vector3) -> CameramanDemoPlayerController:
	var player: CameramanDemoPlayerController = CameramanDemoPlayerController.new()
	player.name = "Player"
	player.position = position
	parent.add_child(player)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = "RedCapsule"
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = 0.45
	capsule.height = 1.8
	mesh.mesh = capsule
	mesh.material_override = material(Color("#e44747"))
	player.add_child(mesh)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.radius = capsule.radius
	shape.height = capsule.height
	collision.shape = shape
	player.add_child(collision)
	var nose: MeshInstance3D = MeshInstance3D.new()
	nose.name = "FacingNose"
	var nose_mesh: BoxMesh = BoxMesh.new()
	nose_mesh.size = Vector3(0.24, 0.24, 0.5)
	nose.mesh = nose_mesh
	nose.position = Vector3(0.0, 0.35, -0.5)
	nose.material_override = material(Color("#2387e8"))
	player.add_child(nose)
	var pivot: Node3D = Node3D.new()
	pivot.name = "PitchPivot"
	pivot.position.y = 0.55
	player.add_child(pivot)
	return player
