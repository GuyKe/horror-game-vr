extends Node3D
## Drives sky/fog color, ambient light and a directional sun/moon light
## through a repeating day-night cycle, ported from the reference project's
## DayNightCycle. Four keyframes (sunrise, noon, sunset, midnight); the
## cycle starts at t=0 (sunrise) and interpolates linearly between
## neighboring keyframes as t advances.

const CYCLE_SECONDS := 480.0
const SUN_RADIUS := 60.0

## [sky, fog, sun, sun_intensity, hemi_sky, hemi_ground, hemi_intensity]
const KEYFRAMES := [
	{
		"sky": Color(1.0, 0.6196, 0.4275),
		"fog": Color(0.8118, 0.4196, 0.2902),
		"sun": Color(1.0, 0.702, 0.4784),
		"sun_intensity": 1.0,
		"hemi_sky": Color(0.5412, 0.5922, 0.6902),
		"hemi_ground": Color(0.1647, 0.1255, 0.0824),
		"hemi_intensity": 0.6,
	},
	{
		"sky": Color(0.749, 0.8902, 1.0),
		"fog": Color(0.6824, 0.8314, 0.9412),
		"sun": Color(1.0, 0.9647, 0.8784),
		"sun_intensity": 1.4,
		"hemi_sky": Color(0.8118, 0.9098, 1.0),
		"hemi_ground": Color(0.2902, 0.251, 0.1882),
		"hemi_intensity": 0.9,
	},
	{
		"sky": Color(1.0, 0.4784, 0.302),
		"fog": Color(0.7098, 0.3373, 0.2353),
		"sun": Color(1.0, 0.5412, 0.302),
		"sun_intensity": 0.9,
		"hemi_sky": Color(0.5412, 0.4157, 0.4471),
		"hemi_ground": Color(0.1647, 0.1255, 0.0824),
		"hemi_intensity": 0.5,
	},
	{
		"sky": Color(0.0118, 0.0157, 0.0353),
		"fog": Color(0.0196, 0.0392, 0.0706),
		"sun": Color(0.4353, 0.5608, 0.7882),
		"sun_intensity": 0.15,
		"hemi_sky": Color(0.1647, 0.2275, 0.3608),
		"hemi_ground": Color(0.0392, 0.0392, 0.0314),
		"hemi_intensity": 0.4,
	},
]

@export var world_environment_path: NodePath
@onready var _env: Environment = get_node(world_environment_path).environment
@onready var _sun_pivot: Node3D = $Sun
@onready var _sun_light: DirectionalLight3D = $Sun/SunLight
@onready var _sun_glow: Sprite3D = $Sun/SunGlow

var _t := 0.0


func _ready() -> void:
	_sun_glow.texture = ProceduralTextures.glow_texture(
		128, Color(1, 1, 1, 1), Color(1, 1, 1, 0)
	)
	_apply_state()


func _process(delta: float) -> void:
	_t = fmod(_t + delta / CYCLE_SECONDS, 1.0)
	_apply_state()


static func _sample(t: float) -> Array:
	var scaled: float = t * KEYFRAMES.size()
	var segment: int = int(floor(scaled)) % KEYFRAMES.size()
	var frac: float = scaled - floor(scaled)
	return [KEYFRAMES[segment], KEYFRAMES[(segment + 1) % KEYFRAMES.size()], frac]


func _apply_state() -> void:
	var sample := _sample(_t)
	var a: Dictionary = sample[0]
	var b: Dictionary = sample[1]
	var frac: float = sample[2]

	var sky_color: Color = a.sky.lerp(b.sky, frac)
	var fog_color: Color = a.fog.lerp(b.fog, frac)
	var sun_color: Color = a.sun.lerp(b.sun, frac)
	var sun_intensity: float = lerpf(a.sun_intensity, b.sun_intensity, frac)
	var hemi_sky: Color = a.hemi_sky.lerp(b.hemi_sky, frac)
	var hemi_ground: Color = a.hemi_ground.lerp(b.hemi_ground, frac)
	var hemi_intensity: float = lerpf(a.hemi_intensity, b.hemi_intensity, frac)

	_env.background_mode = Environment.BG_COLOR
	_env.background_color = sky_color
	_env.fog_enabled = true
	_env.fog_light_color = fog_color
	_env.fog_density = 0.008

	# Godot's ambient/sun energy scale reads much darker than three.js's for
	# the same numeric intensity, so both get a substantial multiplier here
	# on top of the ported values to land at a comparable apparent
	# brightness. Biased toward hemi_sky (rather than a 50/50 blend with
	# hemi_ground) since upward-facing surfaces -- most of what's visible
	# from a standing player -- mainly catch sky-colored ambient light.
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = hemi_sky.lerp(hemi_ground, 0.25)
	_env.ambient_light_energy = hemi_intensity * 3.0

	_sun_light.light_color = sun_color
	_sun_light.light_energy = sun_intensity * 2.5

	var angle: float = _t * TAU
	var sun_pos := Vector3(cos(angle) * SUN_RADIUS, sin(angle) * SUN_RADIUS, -20.0)
	_sun_pivot.position = sun_pos
	if sun_pos.length_squared() > 0.0001:
		_sun_pivot.look_at(Vector3.ZERO, Vector3.UP)

	_sun_glow.modulate = sun_color
	_sun_glow.visible = sun_pos.y > -SUN_RADIUS * 0.08
