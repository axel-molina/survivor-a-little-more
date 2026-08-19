class_name InventorySlotUI
extends Control

## Representa un slot individual en la barra de inventario.

signal slot_selected(slot_index: int)

@export var slot_index: int = 0

var item_data: Dictionary = {} ## { "name": String, "icon": Texture2D, "weapon_scene": PackedScene }
var is_selected: bool = false

@onready var icon_rect: TextureRect = $MarginContainer/IconRect
@onready var number_label: Label = $NumberLabel
@onready var selection_border: Panel = $SelectionBorder


func _ready() -> void:
	if number_label:
		number_label.text = str(slot_index + 1)
	_update_visual()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot_selected.emit(slot_index)


func set_item(data: Dictionary) -> void:
	item_data = data
	_update_visual()


func clear_item() -> void:
	item_data = {}
	_update_visual()


func is_empty() -> bool:
	return item_data.is_empty()


func set_selected(selected: bool) -> void:
	is_selected = selected
	if selection_border:
		selection_border.visible = selected


func _update_visual() -> void:
	if not is_inside_tree():
		return

	if icon_rect:
		if item_data.has("icon") and item_data["icon"] != null:
			icon_rect.texture = item_data["icon"]
			icon_rect.visible = true
		else:
			icon_rect.texture = null
			icon_rect.visible = false
