extends Node3D
## Fire logs, flame/embers, and a fuel timer, unlit by default. Ported from
## bonfire.js: feed it sticks (add_fuel) to ignite it and push back the
## dark; each stick buys SECONDS_PER_STICK of burn time.

const SECONDS_PER_STICK := 60.0
const EMBER_COUNT := 60
const LIGHT_ENERGY := 24.0
const LIGHT_RANGE := 32.0

var is_lit := false
var remaining_seconds := 0.0

@onready var _fire_group: Node3D = $FireGroup
@onready var _light: OmniLight3D = $FireGroup/FireLight
@onready var _embers: MultiMeshInstance3D = $FireGroup/Embers

var _flame_sprites: Array[Sprite3D] = []
var _ember_seeds: Array = []
var _ember_z: Array = []
var _clock := 0.0


func _ready() -> void:
	_build_logs()
	_build_flame()
	_build_embers()
	_light.omni_range = LIGHT_RANGE
	_fire_group.visible = false


func add_fuel(stick_count: int = 1) -> void:
	remaining_seconds += SECONDS_PER_STICK * stick_count
	is_lit = true
	_fire_group.visible = true


func _build_logs() -> void:
	var log_mesh := CylinderMesh.new()
	log_mesh.top_radius = 0.09
	log_mesh.bottom_radius = 0.11
	log_mesh.height = 1.3
	log_mesh.radial_segments = 6
	var log_mat := StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.1412, 0.0784, 0.0314)
	log_mat.roughness = 1.0
	log_mesh.material = log_mat

	var placements := [
		{"rot": 0.3, "y": 0.12},
		{"rot": -0.5, "y": 0.14},
		{"rot": 1.4, "y": 0.1},
		{"rot": 2.3, "y": 0.13},
	]
	for p in placements:
		var log_node := MeshInstance3D.new()
		log_node.mesh = log_mesh
		# Match JS's Euler order (Z applied first, then Y): lay the cylinder
		# on its side around Z, then yaw it around the fire pit around Y.
		var basis := Basis(Vector3.UP, p.rot) * Basis(Vector3(0, 0, 1), PI / 2.0 + sin(p.rot) * 0.15)
		log_node.transform = Transform3D(basis, Vector3(0, p.y, 0))
		add_child(log_node)


func _build_flame() -> void:
	var texture := ProceduralTextures.glow_texture(
		128, Color(1.0, 0.8392, 0.549, 0.95), Color(1.0, 0.3529, 0.0784, 0.0)
	)

	for i in 3:
		var sprite := Sprite3D.new()
		sprite.texture = texture
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.shaded = false
		sprite.transparent = true
		sprite.double_sided = true
		sprite.render_priority = 1

		# Sprite3D's built-in properties can't express additive blending, so
		# an explicit override material carries the same texture with
		# BLEND_MODE_ADD for the glow look.
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_texture = texture
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.material_override = mat

		sprite.position = Vector3(
			randf_range(-0.1, 0.1), 0.5 + i * 0.15, randf_range(-0.1, 0.1)
		)
		var scale: float = 1.1 - i * 0.25
		sprite.scale = Vector3(scale, scale * 1.4, 1.0)
		_fire_group.add_child(sprite)
		_flame_sprites.append(sprite)


func _build_embers() -> void:
	var texture := ProceduralTextures.glow_texture(
		128, Color(1.0, 0.7843, 0.4706, 1.0), Color(1.0, 0.4706, 0.1569, 0.0)
	)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.06, 0.06)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_texture = texture
	quad.material = material

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = quad
	multimesh.instance_count = EMBER_COUNT

	for i in EMBER_COUNT:
		_ember_seeds.append({
			"speed": 0.4 + randf() * 0.6,
			"drift": (randf() - 0.5) * 0.3,
			"offset": randf() * 10.0,
		})
		_ember_z.append((randf() - 0.5) * 0.4)
		multimesh.set_instance_transform(i, Transform3D(Basis(), Vector3((randf() - 0.5) * 0.4, randf() * 1.5, _ember_z[i])))

	_embers.multimesh = multimesh


func _process(delta: float) -> void:
	if not is_lit:
		return

	remaining_seconds -= delta
	if remaining_seconds <= 0.0:
		remaining_seconds = 0.0
		is_lit = false
		_fire_group.visible = false
		return

	_clock += delta
	var elapsed := _clock

	var flicker: float = 0.85 + 0.1 * sin(elapsed * 13.7) + 0.08 * sin(elapsed * 27.1 + 1.3) + 0.05 * sin(elapsed * 5.3)
	_light.light_energy = LIGHT_ENERGY * flicker

	for i in _flame_sprites.size():
		var s := _flame_sprites[i]
		var wobble: float = sin(elapsed * (6.0 + i * 2.0) + i) * 0.08
		s.position.x = wobble
		s.position.z = cos(elapsed * (5.0 + i) + i) * 0.06
		var base_scale: float = 1.1 - i * 0.25
		var scale_flicker: float = base_scale * (0.9 + 0.15 * sin(elapsed * 9.0 + i * 2.0))
		s.scale = Vector3(scale_flicker, scale_flicker * 1.4, 1.0)

	for i in EMBER_COUNT:
		var seed_data: Dictionary = _ember_seeds[i]
		var t: float = fmod(elapsed * seed_data.speed + seed_data.offset, 3.0)
		var y: float = t * 1.2
		var x: float = sin(elapsed + seed_data.offset) * 0.15 + seed_data.drift * t
		_embers.multimesh.set_instance_transform(i, Transform3D(Basis(), Vector3(x, y, _ember_z[i])))
