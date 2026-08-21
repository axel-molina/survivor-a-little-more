class_name LoadingScreen
extends Control

## Pantalla de carga asíncrona con fondo temático y barra de progreso.

@export_file("*.tscn") var target_scene_path: String = "res://scenes/test_scene.tscn"
@export var min_loading_time: float = 2.0

@onready var progress_bar: ProgressBar = $BottomContainer/VBox/ProgressSection/ProgressBar
@onready var percent_label: Label = $BottomContainer/VBox/ProgressSection/HeaderProgress/PercentLabel
@onready var fade_overlay: ColorRect = $FadeOverlay

var _elapsed_time: float = 0.0
var _display_progress: float = 0.0
var _is_transitioning_out: bool = false


func _ready() -> void:
	# Restaurar cursor estándar
	Input.set_custom_mouse_cursor(null)
	
	# Configurar barra en 0
	progress_bar.value = 0.0
	percent_label.text = "0%"
	
	# Iniciar carga en hilo en segundo plano
	var err := ResourceLoader.load_threaded_request(target_scene_path, "", true)
	if err != OK:
		push_error("Error al iniciar carga asíncrona de: %s" % target_scene_path)
	
	# Transición suave de entrada (Fade In desde negro)
	fade_overlay.visible = true
	fade_overlay.modulate.a = 1.0
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(fade_overlay, "modulate:a", 0.0, 0.35)


func _process(delta: float) -> void:
	if _is_transitioning_out:
		return
		
	_elapsed_time += delta
	
	# Consultar el estado real de la carga
	var progress_array: Array = []
	var status := ResourceLoader.load_threaded_get_status(target_scene_path, progress_array)
	
	var raw_progress: float = 0.0
	if progress_array.size() > 0:
		raw_progress = progress_array[0]
		
	# Tiempo ponderado (0.0 a 1.0 según min_loading_time)
	var time_ratio := clampf(_elapsed_time / min_loading_time, 0.0, 1.0)
	
	# El progreso objetivo es el mínimo entre lo cargado y el tiempo requerido
	var target_progress: float = minf(raw_progress, time_ratio)
	if status == ResourceLoader.THREAD_LOAD_LOADED and _elapsed_time >= min_loading_time:
		target_progress = 1.0
		
	# Suavizar el avance visual de la barra
	_display_progress = move_toward(_display_progress, target_progress, delta * 0.9)
	progress_bar.value = _display_progress * 100.0
	percent_label.text = "%d%%" % int(round(_display_progress * 100.0))
	
	# Si se completó la carga y el tiempo mínimo
	if status == ResourceLoader.THREAD_LOAD_LOADED and _elapsed_time >= min_loading_time and _display_progress >= 0.999:
		_finish_loading()


func _finish_loading() -> void:
	if _is_transitioning_out:
		return
	_is_transitioning_out = true
	
	# Fundido a negro antes de entrar al juego
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.35)
	await tween.finished
	
	var packed_scene := ResourceLoader.load_threaded_get(target_scene_path) as PackedScene
	if packed_scene:
		get_tree().change_scene_to_packed(packed_scene)
	else:
		push_error("No se pudo obtener la escena empaquetada: %s" % target_scene_path)
		get_tree().change_scene_to_file(target_scene_path)
