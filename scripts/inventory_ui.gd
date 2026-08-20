class_name InventoryUI
extends CanvasLayer

## Barra de inventario rápido (hotbar) en la parte inferior central de la pantalla.
## Contiene slots numerados donde se equipan automáticamente los objetos recogidos.

signal item_selected(slot_index: int, item_data: Dictionary)

@export var slot_count: int = 6
@export var slot_size: Vector2 = Vector2(64, 64)
@export var slot_spacing: float = 6.0

var _slots: Array[InventorySlotUI] = []
var _selected_slot: int = -1

@onready var hotbar_container: HBoxContainer = $HotbarAnchor/CenterContainer/HotbarPanel/MarginContainer/HotbarContainer


func _ready() -> void:
	if not hotbar_container:
		hotbar_container = find_child("HotbarContainer", true, false) as HBoxContainer

	_create_slots()
	# Seleccionar el primer slot por defecto
	select_slot(0)


func _unhandled_input(event: InputEvent) -> void:
	for i in range(slot_count):
		var action := "slot_%d" % (i + 1)
		if event.is_action_pressed(action) and not event.is_echo():
			if i < _slots.size():
				select_slot(i)
				get_viewport().set_input_as_handled()
				return


func _create_slots() -> void:
	if not hotbar_container:
		return

	for i in range(slot_count):
		var slot := _create_slot_node(i)
		hotbar_container.add_child(slot)
		_slots.append(slot)
		slot.slot_selected.connect(_on_slot_selected)


func _create_slot_node(index: int) -> InventorySlotUI:
	var slot := InventorySlotUI.new()
	slot.slot_index = index
	slot.name = "Slot%d" % index
	slot.custom_minimum_size = slot_size
	slot.mouse_filter = Control.MOUSE_FILTER_STOP

	# Panel de fondo oscuro semi-transparente
	var bg_panel := Panel.new()
	bg_panel.name = "BgPanel"
	bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var slot_style := StyleBoxFlat.new()
	slot_style.bg_color = Color(0.08, 0.08, 0.12, 0.7)
	slot_style.border_color = Color(0.35, 0.35, 0.4, 0.8)
	slot_style.set_border_width_all(2)
	slot_style.set_corner_radius_all(6)
	bg_panel.add_theme_stylebox_override("panel", slot_style)
	slot.add_child(bg_panel)

	# MarginContainer centrado para el ícono
	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(margin)

	# TextureRect para el ícono del ítem (centrado exactamente en el slot)
	var icon_rect := TextureRect.new()
	icon_rect.name = "IconRect"
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.visible = false
	margin.add_child(icon_rect)

	# Label con el número del slot colocado estrictamente en la esquina inferior izquierda
	var number_label := Label.new()
	number_label.name = "NumberLabel"
	number_label.text = str(index + 1)
	number_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	number_label.offset_left = 6
	number_label.offset_top = -20
	number_label.offset_right = 24
	number_label.offset_bottom = -3
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	number_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	number_label.add_theme_font_size_override("font_size", 11)
	number_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 0.95))
	number_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	number_label.add_theme_constant_override("shadow_offset_x", 1)
	number_label.add_theme_constant_override("shadow_offset_y", 1)
	number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(number_label)

	# Panel de selección (borde dorado)
	var selection_border := Panel.new()
	selection_border.name = "SelectionBorder"
	selection_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	selection_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_border.visible = false

	var sel_style := StyleBoxFlat.new()
	sel_style.bg_color = Color(0.0, 0.0, 0.0, 0.0) # Transparente
	sel_style.border_color = Color(1.0, 0.85, 0.3, 1.0) # Borde dorado
	sel_style.set_border_width_all(3)
	sel_style.set_corner_radius_all(6)
	selection_border.add_theme_stylebox_override("panel", sel_style)
	slot.add_child(selection_border)

	return slot


func select_slot(index: int) -> void:
	if index < 0 or index >= _slots.size():
		return

	# Deseleccionar el anterior
	if _selected_slot >= 0 and _selected_slot < _slots.size():
		_slots[_selected_slot].set_selected(false)

	_selected_slot = index
	_slots[_selected_slot].set_selected(true)

	# Emitir señal con los datos del slot
	var data: Dictionary = _slots[_selected_slot].item_data
	item_selected.emit(_selected_slot, data)

	# Notificar directamente al jugador para equipar/desequipar
	var player := get_tree().get_first_node_in_group("player") as PlayerController
	if player:
		player.on_inventory_item_selected(_selected_slot, data)


func _on_slot_selected(slot_index: int) -> void:
	select_slot(slot_index)


## Añade un ítem al primer slot vacío disponible. Retorna el índice del slot o -1 si está lleno.
func add_item(item_name: String, icon: Texture2D, weapon_scene: PackedScene = null) -> int:
	for i in range(_slots.size()):
		if _slots[i].is_empty():
			var data := {
				"name": item_name,
				"icon": icon,
				"weapon_scene": weapon_scene,
			}
			_slots[i].set_item(data)
			return i
	return -1 # Inventario lleno


## Obtiene los datos del slot seleccionado actualmente
func get_selected_item_data() -> Dictionary:
	if _selected_slot >= 0 and _selected_slot < _slots.size():
		return _slots[_selected_slot].item_data
	return {}


## Obtiene el índice del slot seleccionado
func get_selected_slot() -> int:
	return _selected_slot


## Limpia un slot específico
func clear_slot(index: int) -> void:
	if index >= 0 and index < _slots.size():
		_slots[index].clear_item()
