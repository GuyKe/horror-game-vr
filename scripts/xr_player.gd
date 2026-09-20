extends CharacterBody3D
## VR rig: head-relative smooth locomotion + snap turn, trigger-to-teleport,
## and a toggleable flickering flashlight. Movement/turn use the left/right
## controller thumbsticks from Godot's default OpenXR action map.

const MOVE_SPEED := 2.2
const GRAVITY := 9.8
const SNAP_TURN_DEGREES := 30.0
const STICK_DEADZONE := 0.2
const SNAP_TURN_THRESHOLD := 0.6
const SNAP_TURN_RESET := 0.3
const FLASHLIGHT_ENERGY := 3.0

@onready var xr_origin: XROrigin3D = $XROrigin3D
@onready var xr_camera: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var left_hand: XRController3D = $XROrigin3D/LeftHand
@onready var right_hand: XRController3D = $XROrigin3D/RightHand
@onready var flashlight: SpotLight3D = $XROrigin3D/RightHand/Flashlight
@onready var teleport_ray: RayCast3D = $XROrigin3D/RightHand/TeleportRay
@onready var teleport_marker: MeshInstance3D = $TeleportMarker

var _snap_turn_locked := false
var _teleport_aiming := false
var _flashlight_on := true
var _flicker_accum := 0.0


func _ready() -> void:
	right_hand.button_pressed.connect(_on_right_button_pressed)
	right_hand.button_released.connect(_on_right_button_released)
	teleport_marker.visible = false
	flashlight.light_energy = FLASHLIGHT_ENERGY


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_locomotion()
	_handle_snap_turn()
	_handle_teleport_aim()
	_handle_flashlight_flicker(delta)
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta


func _handle_locomotion() -> void:
	var input_vec: Vector2 = left_hand.get_vector2("primary")
	if input_vec.length() < STICK_DEADZONE:
		velocity.x = move_toward(velocity.x, 0.0, MOVE_SPEED)
		velocity.z = move_toward(velocity.z, 0.0, MOVE_SPEED)
		return

	var cam_basis := xr_camera.global_transform.basis
	var forward := -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()

	var move_dir := (forward * -input_vec.y + right * input_vec.x)
	velocity.x = move_dir.x * MOVE_SPEED
	velocity.z = move_dir.z * MOVE_SPEED


func _handle_snap_turn() -> void:
	var turn_vec: Vector2 = right_hand.get_vector2("primary")
	if absf(turn_vec.x) > SNAP_TURN_THRESHOLD and not _snap_turn_locked:
		var angle := SNAP_TURN_DEGREES if turn_vec.x > 0 else -SNAP_TURN_DEGREES
		_rotate_around_head(deg_to_rad(angle))
		_snap_turn_locked = true
	elif absf(turn_vec.x) < SNAP_TURN_RESET:
		_snap_turn_locked = false


func _rotate_around_head(angle: float) -> void:
	var before := xr_camera.global_transform.origin
	xr_origin.rotate_y(angle)
	var after := xr_camera.global_transform.origin
	xr_origin.global_transform.origin += before - after


func _handle_teleport_aim() -> void:
	if not _teleport_aiming:
		return
	teleport_ray.force_raycast_update()
	if teleport_ray.is_colliding() and teleport_ray.get_collision_normal().y > 0.7:
		teleport_marker.visible = true
		teleport_marker.global_position = teleport_ray.get_collision_point()
	else:
		teleport_marker.visible = false


func _on_right_button_pressed(button_name: String) -> void:
	if button_name == "trigger_click":
		_teleport_aiming = true
		teleport_ray.enabled = true
	elif button_name == "ax_button":
		_flashlight_on = not _flashlight_on
		flashlight.visible = _flashlight_on


func _on_right_button_released(button_name: String) -> void:
	if button_name != "trigger_click":
		return
	if _teleport_aiming and teleport_marker.visible:
		_teleport_to(teleport_marker.global_position)
	_teleport_aiming = false
	teleport_ray.enabled = false
	teleport_marker.visible = false


func _teleport_to(target: Vector3) -> void:
	var head_flat := xr_camera.global_transform.origin
	head_flat.y = global_position.y
	var offset := target - head_flat
	global_position += offset


func _handle_flashlight_flicker(delta: float) -> void:
	if not _flashlight_on:
		return
	_flicker_accum += delta
	if _flicker_accum < 0.08:
		return
	_flicker_accum = 0.0
	flashlight.light_energy = FLASHLIGHT_ENERGY + randf_range(-0.35, 0.15)
