extends Node3D
## Scatters low-poly pine-like trees in the ring between the sand clearing
## and the forest's outer radius, using MultiMesh instancing so a few
## hundred trees stay cheap on Quest's mobile GPU. Ported from forest.js;
## same seed (1337) and placement math so the layout matches.

const CLEARING_RADIUS := 9.0
const FOREST_OUTER_RADIUS := 55.0
const TREE_COUNT := 260
const SEED := 1337

@onready var _trunks: MultiMeshInstance3D = $Trunks
@onready var _foliage: MultiMeshInstance3D = $Foliage


func _ready() -> void:
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.12
	trunk_mesh.bottom_radius = 0.2
	trunk_mesh.height = 2.2
	trunk_mesh.radial_segments = 6
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.1686, 0.1137, 0.0745)
	trunk_mat.roughness = 1.0
	trunk_mesh.material = trunk_mat

	var foliage_mesh := CylinderMesh.new()
	foliage_mesh.top_radius = 0.0
	foliage_mesh.bottom_radius = 1.4
	foliage_mesh.height = 3.6
	foliage_mesh.radial_segments = 7
	var foliage_mat := StandardMaterial3D.new()
	foliage_mat.albedo_color = Color(0.0549, 0.1412, 0.0941)
	foliage_mat.roughness = 0.9
	foliage_mesh.material = foliage_mat

	var trunk_multimesh := MultiMesh.new()
	trunk_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	trunk_multimesh.mesh = trunk_mesh
	trunk_multimesh.instance_count = TREE_COUNT

	var foliage_multimesh := MultiMesh.new()
	foliage_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	foliage_multimesh.mesh = foliage_mesh
	foliage_multimesh.instance_count = TREE_COUNT

	var rng := Mulberry32.new(SEED)
	for i in TREE_COUNT:
		var angle: float = rng.next_f32() * TAU
		var radius: float = CLEARING_RADIUS + 1.5 + rng.next_f32() * (FOREST_OUTER_RADIUS - CLEARING_RADIUS)
		var x: float = cos(angle) * radius
		var z: float = sin(angle) * radius
		var scale: float = 0.75 + rng.next_f32() * 0.9
		var rot_y: float = rng.next_f32() * TAU

		# Godot's CylinderMesh is centered on its origin (unlike the JS trunk
		# geometry, which is translated so its origin sits at the base), so
		# the instance position is lifted by half the (scaled) trunk height.
		var trunk_basis := Basis(Vector3.UP, rot_y).scaled(Vector3.ONE * scale)
		trunk_multimesh.set_instance_transform(i, Transform3D(trunk_basis, Vector3(x, 1.1 * scale, z)))

		var foliage_basis := Basis(Vector3.UP, rot_y).scaled(Vector3.ONE * scale)
		foliage_multimesh.set_instance_transform(i, Transform3D(foliage_basis, Vector3(x, 2.6 * scale, z)))

	_trunks.multimesh = trunk_multimesh
	_foliage.multimesh = foliage_multimesh
