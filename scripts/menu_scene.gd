class_name MenuScene
extends Control

## Escena del menú principal del juego.
## Gestiona la navegación entre Jugar, Opciones y Salir.

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton


func _ready() -> void:
	# Restaurar cursor estándar del sistema (no la mira de combate)
	Input.set_custom_mouse_cursor(null)

	# Conectar señales de los botones
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/test_scene.tscn")


func _on_options_pressed() -> void:
	print("Opciones: funcionalidad pendiente de implementar.")


func _on_exit_pressed() -> void:
	get_tree().quit()
