extends Area3D
## Fires the one scripted encounter when the player walks into the trigger
## volume at the end of the corridor. Fires once per session.

@export var entity_path: NodePath
@export var player_path: NodePath

@onready var _entity: Node3D = get_node(entity_path)
@onready var _player: Node3D = get_node(player_path)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if not GameManager.trigger_scare():
		return

	var camera: Node3D = _player.get_node("XROrigin3D/XRCamera3D")
	var head := camera.global_transform.origin
	var forward := -camera.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var spawn_pos := head + forward * 1.2
	spawn_pos.y = _player.global_position.y

	_entity.appear(spawn_pos, head)
