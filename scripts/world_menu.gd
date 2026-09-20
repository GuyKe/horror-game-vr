extends Node3D
## In-world 3D main menu, shown in front of the player at spawn. Reproduces
## the PLAY / TUTORIAL flow as clickable panels the player points at with a
## controller and selects with the trigger. Ported from worldMenu.js
## (rendered with Label3D/procedural textures here instead of canvas-drawn
## sprites, since Godot has no DOM/canvas to draw into).

const PANEL_DISTANCE := 2.4
const PANEL_WIDTH := 2.2
const PANEL_HEIGHT := 1.1
const BUTTON_WIDTH := PANEL_WIDTH * 0.42
const BUTTON_HEIGHT := 0.26
const BUTTON_LAYER := 1 << 3
const FILL_COLOR := Color(1.0, 0.4784, 0.1608, 0.85)
const FILL_COLOR_HOVER := Color(1.0, 0.7255, 0.3765, 0.95)
const LABEL_COLOR := Color(0.102, 0.0588, 0.0235)

var _controllers: Array[XRController3D] = []
var _lines: Array[MeshInstance3D] = []
var _on_play := Callable()
var _on_tutorial := Callable()
var _play_button: Area3D
var _tutorial_button: Area3D
var _play_panel: MeshInstance3D
var _tutorial_panel: MeshInstance3D
var _hovered: Area3D = null


func setup(player: Node3D, camera: XRCamera3D, controllers: Array[XRController3D], on_play: Callable, on_tutorial: Callable) -> void:
	_controllers = controllers
	_on_play = on_play
	_on_tutorial = on_tutorial

	var forward := -camera.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	global_position = player.global_position + forward * PANEL_DISTANCE
	global_position.y = 1.6
	rotation.y = atan2(-forward.x, -forward.z)

	_build_panel()

	for controller in _controllers:
		var line := _build_line()
		controller.add_child(line)
		_lines.append(line)
		controller.button_pressed.connect(_on_button_pressed.bind(controller))

	visible = false


func show_menu() -> void:
	visible = true
	for line in _lines:
		line.visible = true


func hide_menu() -> void:
	visible = false
	for line in _lines:
		line.visible = false


func _build_panel() -> void:
	var bg := MeshInstance3D.new()
	var bg_mesh := PlaneMesh.new()
	bg_mesh.orientation = PlaneMesh.FACE_Z
	bg_mesh.size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	var bg_mat := StandardMaterial3D.new()
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg_mat.albedo_texture = ProceduralTextures.rounded_rect_texture(
		660, 330, 40.0, Color(0.0392, 0.0314, 0.0235, 0.82), Color(1.0, 0.6039, 0.2392, 0.5), 4.0
	)
	bg_mesh.material = bg_mat
	bg.mesh = bg_mesh
	add_child(bg)

	var title := Label3D.new()
	title.text = "Fifi's Forest"
	title.font_size = 72
	title.pixel_size = 0.0032
	title.modulate = Color(1.0, 0.8118, 0.5569)
	title.outline_modulate = Color(1.0, 0.549, 0.1569, 0.6)
	title.outline_size = 12
	title.position = Vector3(0, PANEL_HEIGHT * 0.26, 0.005)
	add_child(title)

	_play_button = _make_button("PLAY")
	_play_button.position = Vector3(-PANEL_WIDTH * 0.16, -0.24, 0.005)
	_play_panel = _play_button.get_node("Panel")
	add_child(_play_button)

	_tutorial_button = _make_button("TUTORIAL")
	_tutorial_button.position = Vector3(PANEL_WIDTH * 0.16, -0.24, 0.005)
	_tutorial_panel = _tutorial_button.get_node("Panel")
	add_child(_tutorial_button)


func _make_button(label: String) -> Area3D:
	var area := Area3D.new()
	area.collision_layer = BUTTON_LAYER
	area.collision_mask = 0

	var panel := MeshInstance3D.new()
	panel.name = "Panel"
	var mesh := PlaneMesh.new()
	mesh.orientation = PlaneMesh.FACE_Z
	mesh.size = Vector2(BUTTON_WIDTH, BUTTON_HEIGHT)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = ProceduralTextures.rounded_rect_texture(
		400, 130, 32.0, FILL_COLOR
	)
	mesh.material = mat
	panel.mesh = mesh
	area.add_child(panel)

	var text := Label3D.new()
	text.text = label
	text.font_size = 40
	text.pixel_size = 0.003
	text.modulate = LABEL_COLOR
	text.position = Vector3(0, 0, 0.002)
	area.add_child(text)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(BUTTON_WIDTH, BUTTON_HEIGHT, 0.05)
	shape.shape = box
	area.add_child(shape)

	return area


func _build_line() -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.702, 0.2784)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mat
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.visible = false
	instance.transform = Transform3D().scaled(Vector3(0.006, 0.006, PANEL_DISTANCE + 1.0))
	instance.position = Vector3(0, 0, -(PANEL_DISTANCE + 1.0) / 2.0)
	return instance


func _raycast_buttons(controller: XRController3D) -> Area3D:
	var space_state := controller.get_world_3d().direct_space_state
	var origin := controller.global_position
	var forward := -controller.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(origin, origin + forward * (PANEL_DISTANCE + 1.0))
	query.collision_mask = BUTTON_LAYER
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	return hit.collider as Area3D


func _on_button_pressed(button_name: String, controller: XRController3D) -> void:
	if button_name != "trigger_click" or not visible:
		return
	var target := _raycast_buttons(controller)
	if target == _play_button:
		_on_play.call()
	elif target == _tutorial_button:
		_on_tutorial.call()


func _process(_delta: float) -> void:
	if not visible:
		return

	var hovered: Area3D = null
	for controller in _controllers:
		var hit := _raycast_buttons(controller)
		if hit:
			hovered = hit
			break

	if hovered != _hovered:
		_set_hover(_hovered, false)
		_set_hover(hovered, true)
		_hovered = hovered


func _set_hover(button: Area3D, hovered: bool) -> void:
	if button == null:
		return
	var panel: MeshInstance3D = button.get_node("Panel")
	var mat: StandardMaterial3D = panel.mesh.material
	mat.albedo_texture = ProceduralTextures.rounded_rect_texture(
		400, 130, 32.0, FILL_COLOR_HOVER if hovered else FILL_COLOR
	)
