class_name PickupItem
extends Area3D

## Componente para objetos interactuables en el suelo que pueden ser recogidos por el jugador.
## Muestra un borde rojo brillante en el modelo y un indicador UI al estar en rango.

@export_group("Datos del Objeto")
@export var item_name: String = "Bate"
@export var action_text: String = "para tomar Bate"
@export var weapon_packed_scene: PackedScene = preload("res://assets/Low Poly Weapon Pack with Image Texture - by Kickin It Studios/Weapons for Itch with image texture.fbx_Bat.fbx")
@export var item_icon: Texture2D ## Ícono del objeto para mostrar en el inventario

@export_group("Resaltado Visual (Outline)")
@export var target_mesh: MeshInstance3D
@export var outline_color: Color = Color(1.0, 0.15, 0.15, 1.0)
@export var outline_width: float = 0.03

var _outline_material: ShaderMaterial
var _current_player: PlayerController


func _ready() -> void:
	# Buscar MeshInstance3D si no se asignó manualmente
	if not target_mesh:
		var meshes := find_children("*", "MeshInstance3D", true, false)
		if not meshes.is_empty():
			target_mesh = meshes[0] as MeshInstance3D

	# Crear el material de outline con el shader
	_setup_outline_material()

	# Conectar señales del Area3D
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _setup_outline_material() -> void:
	var shader := load("res://shaders/outline.gdshader") as Shader
	if shader:
		_outline_material = ShaderMaterial.new()
		_outline_material.shader = shader
		_outline_material.set_shader_parameter("outline_color", outline_color)
		_outline_material.set_shader_parameter("outline_width", outline_width)


func _on_body_entered(body: Node3D) -> void:
	if body is PlayerController or body.is_in_group("player"):
		var player := body as PlayerController
		if player:
			_current_player = player
			player.set_current_interactable(self)

		# Activar borde rojo
		_set_outline_active(true)

		# Mostrar UI de interacción
		var ui := get_tree().get_first_node_in_group("interaction_ui") as InteractionUI
		if ui:
			ui.show_prompt(action_text, "F")


func _on_body_exited(body: Node3D) -> void:
	if body == _current_player:
		if _current_player and _current_player.get_current_interactable() == self:
			_current_player.set_current_interactable(null)
		_current_player = null

		# Desactivar borde rojo
		_set_outline_active(false)

		# Ocultar UI de interacción
		var ui := get_tree().get_first_node_in_group("interaction_ui") as InteractionUI
		if ui:
			ui.hide_prompt()


func _set_outline_active(active: bool) -> void:
	if not is_instance_valid(target_mesh):
		return

	if active and _outline_material:
		target_mesh.material_overlay = _outline_material
	else:
		target_mesh.material_overlay = null


## Método ejecutado cuando el jugador presiona F para recoger el objeto
func pickup(player: PlayerController) -> void:
	# Ocultar UI
	var ui := get_tree().get_first_node_in_group("interaction_ui") as InteractionUI
	if ui:
		ui.hide_prompt()

	# Quitar outline
	_set_outline_active(false)

	# Desvincular del player
	if player.get_current_interactable() == self:
		player.set_current_interactable(null)

	# Añadir al inventario
	var inventory := get_tree().get_first_node_in_group("inventory_ui") as InventoryUI
	if inventory:
		inventory.add_item(item_name, item_icon, weapon_packed_scene)

	# Equipar en la mano del jugador
	if weapon_packed_scene:
		player.equip_right_hand(weapon_packed_scene)

	# Eliminar el objeto del suelo (o el nodo raíz del bate)
	var root_node := get_parent() if get_parent() and get_parent().name == "Bat" else self
	root_node.queue_free()

