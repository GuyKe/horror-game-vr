class_name InteractionManager
extends RefCounted
## Tracks registered Interactables and which one (if any) the player is
## currently standing near, so a controller trigger press can act on it.
## Ported from interactions.js.

var player: Node3D
var items: Array[Interactable] = []
var nearby: Interactable = null


func _init(player_node: Node3D) -> void:
	player = player_node


func register(item: Interactable) -> Interactable:
	items.append(item)
	return item


func unregister(item: Interactable) -> void:
	items.erase(item)
	if nearby == item:
		nearby = null


func update() -> void:
	var nearest: Interactable = null
	var nearest_dist := INF
	var pos := player.global_position
	for item in items:
		var p := item.global_position()
		var dist := Vector2(pos.x - p.x, pos.z - p.z).length()
		if dist <= item.radius and dist < nearest_dist:
			nearest = item
			nearest_dist = dist
	nearby = nearest


func interact() -> void:
	if nearby:
		nearby.on_interact.call()
