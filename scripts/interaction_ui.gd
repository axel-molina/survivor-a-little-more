class_name InteractionUI
extends CanvasLayer

## Interfaz de usuario para mostrar indicadores de interacción en pantalla ("[F] para tomar").

@onready var prompt_container: Control = $PromptContainer
@onready var prompt_label: Label = $PromptContainer/PanelContainer/MarginContainer/HBoxContainer/PromptLabel
@onready var key_badge: Label = $PromptContainer/PanelContainer/MarginContainer/HBoxContainer/KeyBadge


func _ready() -> void:
	# Iniciar oculto por defecto
	hide_prompt()


## Muestra el cartel de interacción con el texto especificado.
func show_prompt(action_text: String = "tomar", key_text: String = "F") -> void:
	if key_badge:
		key_badge.text = key_text
	if prompt_label:
		prompt_label.text = action_text
	if prompt_container:
		prompt_container.visible = true


## Oculta el cartel de interacción.
func hide_prompt() -> void:
	if prompt_container:
		prompt_container.visible = false
