extends Node3D
## VR rig: head-relative smooth (joystick) locomotion only, ported from
## vrLocomotion.js. The reference project has no gravity or world collision
## at all -- movement is flat XZ translation -- so this doesn't either;
## floor-tracked OpenXR already reports the player's real standing height.

const MOVE_SPEED := 2.6
const DEADZONE := 0.15

@onready var xr_camera: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var left_hand: XRController3D = $XROrigin3D/LeftHand
@onready var right_hand: XRController3D = $XROrigin3D/RightHand


func _physics_process(delta: float) -> void:
	var input_vec: Vector2 = left_hand.get_vector2("primary")
	if absf(input_vec.x) < DEADZONE:
		input_vec.x = 0.0
	if absf(input_vec.y) < DEADZONE:
		input_vec.y = 0.0
	if input_vec == Vector2.ZERO:
		return

	var cam_basis := xr_camera.global_transform.basis
	var forward := -cam_basis.z
	forward.y = 0.0
	if forward.length_squared() < 1e-6:
		return
	forward = forward.normalized()
	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()

	# Thumbstick y is negative when pushed forward.
	var move := forward * -input_vec.y + right * input_vec.x
	if move.length_squared() > 1.0:
		move = move.normalized()

	global_position += move * MOVE_SPEED * delta
