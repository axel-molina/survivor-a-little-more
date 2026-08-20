class_name PauseMenu
extends CanvasLayer

## Controlador del menú de pausa.
## Detiene la ejecución del juego, aplica el efecto de desenfoque y reproduce SFX de UI.

@export var hover_sfx: AudioStream = preload("res://sfx/ui/hover_sound.mp3")
@export var submit_sfx: AudioStream = preload("res://sfx/ui/submit_sound.wav")

@onready var pause_control: Control = $PauseControl
@onready var resume_button: Button = $PauseControl/CenterContainer/VBoxContainer/ResumeButton
@onready var options_button: Button = $PauseControl/CenterContainer/VBoxContainer/OptionsButton
@onready var exit_button: Button = $PauseControl/CenterContainer/VBoxContainer/ExitButton

var is_paused: bool = false
var _hover_player: AudioStreamPlayer
var _submit_player: AudioStreamPlayer


func _ready() -> void:
	# El menú de pausa debe procesar siempre, incluso con el juego pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Asegurar estado inicial oculto
	pause_control.visible = false
	is_paused = false
	
	_setup_audio_players()
	_setup_button_sounds()
	
	# Conectar botones
	resume_button.pressed.connect(_on_resume_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)


func _setup_audio_players() -> void:
	_hover_player = AudioStreamPlayer.new()
	_hover_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_hover_player.stream = hover_sfx
	_hover_player.bus = &"Master"
	add_child(_hover_player)

	_submit_player = AudioStreamPlayer.new()
	_submit_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_submit_player.stream = submit_sfx
	_submit_player.bus = &"Master"
	add_child(_submit_player)


func _setup_button_sounds() -> void:
	var buttons: Array[Button] = [resume_button, options_button, exit_button]
	for btn in buttons:
		if btn:
			btn.mouse_entered.connect(_play_hover_sfx)
			btn.focus_entered.connect(_play_hover_sfx)


func _play_hover_sfx() -> void:
	if is_paused and _hover_player and hover_sfx:
		_hover_player.play()


func _play_submit_sfx() -> void:
	if _submit_player and submit_sfx:
		_submit_player.play()


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
	_play_submit_sfx()
	resume_game()


var options_menu_scene: PackedScene = preload("res://scenes/options_menu.tscn")

func _on_options_pressed() -> void:
	_play_submit_sfx()
	var opts = options_menu_scene.instantiate()
	add_child(opts)
	opts.closed.connect(func(): pause_control.show())
	pause_control.hide()


func _on_exit_pressed() -> void:
	_play_submit_sfx()
	await get_tree().create_timer(0.15).timeout
	get_tree().paused = false
	Input.set_custom_mouse_cursor(null)
	get_tree().change_scene_to_file("res://scenes/menu_scene.tscn")
