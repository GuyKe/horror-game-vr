extends Node3D
## Root orchestrator: mode state (menu/play/tutorial), spawn points, and
## wiring between the player, interactions, grab system, bonfire, pickups,
## tutorial and world menu. Ported from main.js.

const FOREST_SPAWN_POSITION := Vector3(0, 0, 3.5)
const FOREST_SPAWN_YAW := PI
const BONFIRE_INTERACT_RADIUS := 2.4

@onready var player: Node3D = $XRPlayer
@onready var camera: XRCamera3D = $XRPlayer/XROrigin3D/XRCamera3D
@onready var left_hand: XRController3D = $XRPlayer/XROrigin3D/LeftHand
@onready var right_hand: XRController3D = $XRPlayer/XROrigin3D/RightHand
@onready var bonfire: Node3D = $WorldGroup/Bonfire
@onready var pickups_spawner: Node3D = $WorldGroup/Pickups
@onready var tutorial: Node3D = $Tutorial
@onready var world_menu: Node3D = $WorldMenu

var inventory := {"sticks": 0, "rocks": 0}
var mode := "menu"  # "menu" | "play" | "tutorial"

var _interactions: InteractionManager
var _grab_system: GrabSystem
var _prompt_label: Label3D
var _hud_label: Label3D


func _ready() -> void:
	_interactions = InteractionManager.new(player)
	tutorial.setup(player)

	var bonfire_item := Interactable.new()
	bonfire_item.target = bonfire
	bonfire_item.radius = BONFIRE_INTERACT_RADIUS
	bonfire_item.grabbable = false
	bonfire_item.get_label = func() -> String:
		if inventory.sticks > 0:
			return "Press trigger to add a stick to the fire (have %d)" % inventory.sticks
		if bonfire.is_lit:
			return "Fire burning -- %ds left" % int(ceil(bonfire.remaining_seconds))
		return "Find a stick to light the fire"
	bonfire_item.on_interact = func() -> void:
		if inventory.sticks <= 0:
			return
		inventory.sticks -= 1
		bonfire.add_fuel(1)
	_interactions.register(bonfire_item)

	pickups_spawner.setup(_interactions, inventory, Callable())

	_grab_system = GrabSystem.new(player, [left_hand, right_hand], _interactions)
	add_child(_grab_system)
	_grab_system.enabled = false

	world_menu.setup(player, camera, [left_hand, right_hand], _enter_play, _enter_tutorial)

	_build_hud()

	left_hand.button_pressed.connect(_on_controller_trigger)
	right_hand.button_pressed.connect(_on_controller_trigger)

	_enter_menu()


func _build_hud() -> void:
	_prompt_label = Label3D.new()
	_prompt_label.font_size = 28
	_prompt_label.pixel_size = 0.0028
	_prompt_label.modulate = Color(1.0, 0.9137, 0.7804)
	_prompt_label.outline_size = 8
	_prompt_label.outline_modulate = Color(0, 0, 0, 0.9)
	_prompt_label.position = Vector3(0, -0.22, -1.0)
	_prompt_label.visible = false
	camera.add_child(_prompt_label)

	_hud_label = Label3D.new()
	_hud_label.font_size = 22
	_hud_label.pixel_size = 0.0024
	_hud_label.modulate = Color(0.9490, 0.9098, 0.8353)
	_hud_label.outline_size = 6
	_hud_label.outline_modulate = Color(0, 0, 0, 0.9)
	_hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_hud_label.position = Vector3(-0.45, -0.32, -1.0)
	_hud_label.visible = false
	camera.add_child(_hud_label)


func _on_controller_trigger(button_name: String) -> void:
	if button_name != "trigger_click" or mode == "menu":
		return
	if _interactions.nearby != null and _interactions.nearby.grabbable:
		return
	_interactions.interact()


func _process(_delta: float) -> void:
	if mode != "menu":
		_interactions.update()
		if _interactions.nearby != null:
			_prompt_label.text = _interactions.nearby.get_label.call()
			_prompt_label.visible = true
		else:
			_prompt_label.visible = false

	_hud_label.visible = mode == "play"
	if mode == "play":
		_hud_label.text = "Sticks: %d   Rocks: %d" % [inventory.sticks, inventory.rocks]


func _go_to_forest_spawn() -> void:
	player.global_position = FOREST_SPAWN_POSITION
	player.rotation.y = FOREST_SPAWN_YAW


func _enter_menu() -> void:
	mode = "menu"
	tutorial.hide_tutorial()
	_go_to_forest_spawn()
	_grab_system.enabled = false
	world_menu.show_menu()


func _enter_play() -> void:
	mode = "play"
	world_menu.hide_menu()
	_grab_system.enabled = true


func _enter_tutorial() -> void:
	mode = "tutorial"
	world_menu.hide_menu()
	_grab_system.enabled = false
	tutorial.show_tutorial(_enter_menu)
