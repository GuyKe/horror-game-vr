extends Node3D
## A bare-bones "walk to the dot" exercise: teaches joystick locomotion on a
## plain baseplate, away from the forest. Reaching the glowing dot fires the
## completion callback passed to show_tutorial(). Ported from tutorial.js.

const BASEPLATE_CENTER := Vector3(0, 0, -260)
const SPAWN_OFFSET := Vector3(0, 0, 4)
const DOT_OFFSET := Vector3(0, 0, -4)
const REACH_DISTANCE := 0.7

var active := false

@onready var _plate: MeshInstance3D = $Plate
@onready var _dot: MeshInstance3D = $Dot

var _player: Node3D
var _clock := 0.0
var _on_complete := Callable()


func _ready() -> void:
	position = BASEPLATE_CENTER
	visible = false

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ProceduralTextures.grid_texture(
		512, Color(0.2941, 0.3333, 0.3765), Color(1, 1, 1, 0.15), 8
	)
	mat.roughness = 0.9
	_plate.mesh.material = mat


func setup(player: Node3D) -> void:
	_player = player


func show_tutorial(on_complete: Callable) -> void:
	_on_complete = on_complete
	active = true
	visible = true
	_player.global_position = BASEPLATE_CENTER + SPAWN_OFFSET
	_player.rotation.y = 0.0


func hide_tutorial() -> void:
	active = false
	visible = false


func _process(delta: float) -> void:
	if not active or _player == null:
		return
	_clock += delta
	var pulse: float = 1.0 + 0.15 * sin(_clock * 4.0)
	_dot.scale = Vector3(pulse, 1.0, pulse)

	var dot_world := _dot.global_position
	var d := Vector2(_player.global_position.x - dot_world.x, _player.global_position.z - dot_world.z).length()
	if d < REACH_DISTANCE:
		active = false
		visible = false
		var callback := _on_complete
		_on_complete = Callable()
		if callback.is_valid():
			callback.call()
