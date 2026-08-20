class_name PauseMenu
extends CanvasLayer

## Controlador del menú de pausa.
## Detiene la ejecución del juego, aplica el efecto de desenfoque y muestra las opciones de navegación.

@onready var pause_control: Control = $PauseControl
@onready var resume_button: Button = $PauseControl/CenterContainer/VBoxContainer/ResumeButton
@onready var options_button: Button = $PauseControl/CenterContainer/VBoxContainer/OptionsButton
@onready var exit_button: Button = $PauseControl/CenterContainer/VBoxContainer/ExitButton

var is_paused: bool = false


func _ready() -> void:
	# El menú de pausa debe procesar siempre, incluso con el juego pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Asegurar estado inicial oculto
	pause_control.visible = false
	is_paused = false
	
	# Conectar botones
	resume_button.pressed.connect(_on_resume_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()


func pause_game() -> void:
	is_paused = true
	get_tree().paused = true
	pause_control.visible = true
	
	# Restaurar cursor estándar del sistema para seleccionar botones
	Input.set_custom_mouse_cursor(null)
	
	# Dar foco al botón de Continuar
	resume_button.grab_focus()


func resume_game() -> void:
	is_paused = false
	pause_control.visible = false
	get_tree().paused = false
	
	# Restaurar la mira de combate del jugador si está presente
	var player := get_tree().get_first_node_in_group("player") as PlayerController
	if player:
		player._setup_custom_crosshair()


func _on_resume_pressed() -> void:
	resume_game()


func _on_options_pressed() -> void:
	print("Opciones en pausa: funcionalidad pendiente de implementar.")


func _on_exit_pressed() -> void:
	# Asegurar que el árbol se despause antes de cambiar de escena
	get_tree().paused = false
	Input.set_custom_mouse_cursor(null)
	get_tree().change_scene_to_file("res://scenes/menu_scene.tscn")
