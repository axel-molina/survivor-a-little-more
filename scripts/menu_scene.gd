class_name MenuScene
extends Control

## Escena del menú principal del juego.
## Gestiona la navegación entre Jugar, Opciones y Salir, con efectos de sonido SFX.

@export var hover_sfx: AudioStream = preload("res://sfx/ui/hover_sound.mp3")
@export var submit_sfx: AudioStream = preload("res://sfx/ui/submit_sound.wav")

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton

var _hover_player: AudioStreamPlayer
var _submit_player: AudioStreamPlayer


func _ready() -> void:
	# Restaurar cursor estándar del sistema (no la mira de combate)
	Input.set_custom_mouse_cursor(null)

	_setup_audio_players()
	_setup_button_sounds()

	# Conectar señales de los botones
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)


func _setup_audio_players() -> void:
	_hover_player = AudioStreamPlayer.new()
	_hover_player.stream = hover_sfx
	_hover_player.bus = &"Master"
	add_child(_hover_player)

	_submit_player = AudioStreamPlayer.new()
	_submit_player.stream = submit_sfx
	_submit_player.bus = &"Master"
	add_child(_submit_player)


func _setup_button_sounds() -> void:
	var buttons: Array[Button] = [play_button, options_button, exit_button]
	for btn in buttons:
		if btn:
			btn.mouse_entered.connect(_play_hover_sfx)
			btn.focus_entered.connect(_play_hover_sfx)


func _play_hover_sfx() -> void:
	if _hover_player and hover_sfx:
		_hover_player.play()


func _play_submit_sfx() -> void:
	if _submit_player and submit_sfx:
		_submit_player.play()


func _on_play_pressed() -> void:
	_play_submit_sfx()
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")


@onready var menu_container: VBoxContainer = $VBoxContainer

var options_menu_scene: PackedScene = preload("res://scenes/options_menu.tscn")

func _on_options_pressed() -> void:
	_play_submit_sfx()
	var opts = options_menu_scene.instantiate()
	add_child(opts)
	opts.closed.connect(func(): menu_container.show())
	menu_container.hide()


func _on_exit_pressed() -> void:
	_play_submit_sfx()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()
