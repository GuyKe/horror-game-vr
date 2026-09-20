extends Node3D
## The scripted scare: pops into existence in front of the player, holds for
## a beat, then retreats. Plays the procedurally generated stinger from
## GameManager so no audio asset is needed.

@onready var audio: AudioStreamPlayer3D = $Stinger


func appear(at: Vector3, look_target: Vector3) -> void:
	global_position = at
	look_at(look_target, Vector3.UP)
	visible = true
	scale = Vector3.ZERO

	audio.stream = GameManager.stinger_stream
	audio.play()

	var in_tween := create_tween()
	in_tween.tween_property(self, "scale", Vector3.ONE, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(1.4).timeout

	var out_tween := create_tween()
	out_tween.tween_property(self, "scale", Vector3.ZERO, 0.25) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await out_tween.finished
	visible = false
