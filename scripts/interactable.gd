class_name Interactable
extends RefCounted
## One registered "thing you can walk up to and press the trigger on"
## (bonfire, sticks, rocks). Ported from the reference project's plain
## interaction-item objects in interactions.js / pickups.js.

var target: Node3D
var radius: float
var grabbable := false
## Raycast target for GrabSystem when grabbable is true.
var mesh: Node3D
var get_label: Callable
var on_interact: Callable


func global_position() -> Vector3:
	return target.global_position
