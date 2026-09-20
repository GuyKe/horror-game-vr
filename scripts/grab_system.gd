class_name GrabSystem
extends Node
## VR "force grab" for loose pickups: point a controller at a stick or rock
## and a line appears; hold the trigger and it flies into your hand over
## GRAB_DURATION, completing the same pickup as a proximity tap would.
## Releasing the trigger early snaps it back to where it started. Ported
## from grabSystem.js.

const MAX_GRAB_DISTANCE := 10.0
const GRAB_DURATION := 0.35
const GRABBABLE_LAYER := 1 << 2
const LINE_COLOR := Color(0.6235, 0.9098, 1.0)

var enabled := true

var _player: Node3D
var _interactions: InteractionManager
var _controllers: Array[XRController3D]
var _lines: Array[MeshInstance3D] = []
var _hovered: Array = [null, null]
var _pulls: Array = [null, null]


func _init(player: Node3D, controllers: Array[XRController3D], interactions: InteractionManager) -> void:
	_player = player
	_controllers = controllers
	_interactions = interactions

	for controller in _controllers:
		var line := _build_line()
		controller.add_child(line)
		_lines.append(line)
		controller.button_pressed.connect(_on_button_pressed.bind(controller))
		controller.button_released.connect(_on_button_released.bind(controller))


func _build_line() -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	var mat := StandardMaterial3D.new()
	mat.albedo_color = LINE_COLOR
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mat
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.visible = false
	return instance


func _grabbable_items() -> Array[Interactable]:
	var result: Array[Interactable] = []
	for item in _interactions.items:
		if item.grabbable:
			result.append(item)
	return result


func _raycast_from(controller: XRController3D) -> Dictionary:
	var space_state := controller.get_world_3d().direct_space_state
	var origin := controller.global_position
	var forward := -controller.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(origin, origin + forward * MAX_GRAB_DISTANCE)
	query.collision_mask = GRABBABLE_LAYER
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return {}
	for item in _grabbable_items():
		if item.mesh == hit.collider:
			return {"item": item, "distance": origin.distance_to(hit.position)}
	return {}


func _on_button_pressed(button_name: String, controller: XRController3D) -> void:
	if button_name != "trigger_click" or not enabled:
		return
	var i := _controllers.find(controller)
	var hovered: Interactable = _hovered[i]
	if hovered == null or not _interactions.items.has(hovered):
		return

	var body := hovered.mesh
	var global_xform := body.global_transform
	body.get_parent().remove_child(body)
	_player.add_child(body)
	body.global_transform = global_xform

	_pulls[i] = {
		"item": hovered,
		"body": body,
		"controller": controller,
		"start_local": body.position,
		"elapsed": 0.0,
	}
	_lines[i].visible = false


func _on_button_released(button_name: String, controller: XRController3D) -> void:
	if button_name != "trigger_click":
		return
	var i := _controllers.find(controller)
	var pull = _pulls[i]
	if pull == null:
		return
	pull.body.position = pull.start_local
	_pulls[i] = null


func _process(delta: float) -> void:
	if not enabled:
		for line in _lines:
			line.visible = false
		return

	for i in _controllers.size():
		if _pulls[i] != null:
			continue
		var hit := _raycast_from(_controllers[i])
		_hovered[i] = hit.get("item")
		var line := _lines[i]
		if hit.is_empty():
			line.visible = false
			continue
		line.visible = true
		var distance: float = hit["distance"]
		var t := Transform3D().scaled(Vector3(0.006, 0.006, distance))
		t.origin = Vector3(0, 0, -distance / 2.0)
		line.transform = t

	for i in _pulls.size():
		var pull = _pulls[i]
		if pull == null:
			continue
		pull.elapsed += delta
		var t: float = minf(pull.elapsed / GRAB_DURATION, 1.0)
		var hand_local: Vector3 = _player.to_local(pull.controller.global_position)
		pull.body.position = pull.start_local.lerp(hand_local, t)

		if t >= 1.0:
			pull.item.on_interact.call()
			_pulls[i] = null
