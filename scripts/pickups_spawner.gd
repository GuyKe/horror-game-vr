extends Node3D
## Scatters pickable sticks and rocks around the clearing and registers each
## with the InteractionManager; picking one up removes its mesh and bumps
## the shared inventory counts. Ported from pickups.js; same seed (4242)
## and placement math so the layout matches.

const STICK_COUNT := 6
const ROCK_COUNT := 6
const SCATTER_MIN_RADIUS := 2.5
const SCATTER_MAX_RADIUS := 7.5
const PICKUP_RADIUS := 1.3
const SEED := 4242

## Grabbable pickups live on their own physics layer (3rd bit) so
## GrabSystem's raycasts can target them without also hitting the ground/
## trees/player.
const GRABBABLE_LAYER := 1 << 2


## interactions: InteractionManager, inventory: Dictionary (mutated in
## place), on_change: Callable() called after an item is picked up.
func setup(interactions: InteractionManager, inventory: Dictionary, on_change: Callable) -> void:
	var rng := Mulberry32.new(SEED)
	for i in STICK_COUNT:
		_scatter_one(rng, "stick", _make_stick_mesh(), interactions, inventory, on_change)
	for i in ROCK_COUNT:
		_scatter_one(rng, "rock", _make_rock_mesh(rng), interactions, inventory, on_change)


func _scatter_one(rng: Mulberry32, kind: String, mesh_instance: MeshInstance3D, interactions: InteractionManager, inventory: Dictionary, on_change: Callable) -> void:
	var angle: float = rng.next_f32() * TAU
	var radius: float = SCATTER_MIN_RADIUS + rng.next_f32() * (SCATTER_MAX_RADIUS - SCATTER_MIN_RADIUS)
	var y: float = 0.05 if kind == "stick" else 0.12

	var body := Area3D.new()
	body.collision_layer = GRABBABLE_LAYER
	body.collision_mask = 0
	body.position = Vector3(cos(angle) * radius, y, sin(angle) * radius)
	body.add_child(mesh_instance)

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.25
	shape.shape = sphere
	body.add_child(shape)

	add_child(body)

	var item := Interactable.new()
	item.target = body
	item.radius = PICKUP_RADIUS
	item.grabbable = true
	item.mesh = body
	item.get_label = func() -> String:
		return "Press trigger to pick up %s" % kind

	var inventory_key := "sticks" if kind == "stick" else "rocks"
	var registered: Interactable = interactions.register(item)
	item.on_interact = func() -> void:
		inventory[inventory_key] += 1
		on_change.call()
		body.get_parent().remove_child(body)
		body.queue_free()
		interactions.unregister(registered)


func _make_stick_mesh() -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.03
	mesh.bottom_radius = 0.04
	mesh.height = 0.9
	mesh.radial_segments = 6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2902, 0.1843, 0.102)
	mat.roughness = 1.0
	mesh.material = mat

	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.rotation.z = PI / 2.2
	return instance


func _make_rock_mesh(rng: Mulberry32) -> MeshInstance3D:
	# Godot's PrimitiveMesh set has no icosahedron; a very low-segment
	# sphere is the closest cheap faceted stand-in.
	var mesh := SphereMesh.new()
	mesh.radius = 0.16 + rng.next_f32() * 0.08
	mesh.height = mesh.radius * 2.0
	mesh.radial_segments = 7
	mesh.rings = 4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4196, 0.4196, 0.4196)
	mat.roughness = 0.95
	mesh.material = mat

	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.rotation = Vector3(rng.next_f32() * TAU, rng.next_f32() * TAU, rng.next_f32() * TAU)
	return instance
