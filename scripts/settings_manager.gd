extends Node

const SETTINGS_FILE_PATH = "user://settings.cfg"

var config := ConfigFile.new()

# Claves de configuración
const SECTION_VIDEO = "video"
const SECTION_AUDIO = "audio"
const SECTION_GENERAL = "general"
const SECTION_CONTROLS = "controls"

signal settings_applied


func _ready() -> void:
	# Este nodo no debe pausarse, para que las opciones puedan cambiarse
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()


func load_settings() -> void:
	var err = config.load(SETTINGS_FILE_PATH)
	if err != OK:
		# Si no existe, configurar valores por defecto
		_setup_default_settings()
		save_settings()
	
	apply_all_settings()


func save_settings() -> void:
	config.save(SETTINGS_FILE_PATH)


func _setup_default_settings() -> void:
	# Video
	config.set_value(SECTION_VIDEO, "fullscreen", true)
	# Resolución por defecto = resolución actual de la pantalla
	var screen_size = DisplayServer.screen_get_size()
	config.set_value(SECTION_VIDEO, "resolution_w", screen_size.x)
	config.set_value(SECTION_VIDEO, "resolution_h", screen_size.y)
	config.set_value(SECTION_VIDEO, "fps_limit", 60)
	
	# Audio (1.0 = 0 dB)
	config.set_value(SECTION_AUDIO, "master", 1.0)
	config.set_value(SECTION_AUDIO, "music", 1.0)
	config.set_value(SECTION_AUDIO, "sfx", 1.0)
	
	# General
	config.set_value(SECTION_GENERAL, "language", "es")
	
	# Controles
	# No establecemos defaults aquí, sino que en tiempo de ejecución tomamos
	# el InputMap si la clave no existe en la config.


func apply_all_settings() -> void:
	# --- Video ---
	var is_fullscreen = config.get_value(SECTION_VIDEO, "fullscreen", true)
	set_fullscreen(is_fullscreen, false)
	
	var res_w = config.get_value(SECTION_VIDEO, "resolution_w", 1920)
	var res_h = config.get_value(SECTION_VIDEO, "resolution_h", 1080)
	set_resolution(Vector2i(res_w, res_h), false)
	
	var fps = config.get_value(SECTION_VIDEO, "fps_limit", 60)
	set_fps_limit(fps, false)
	
	# --- Audio ---
	set_volume("Master", config.get_value(SECTION_AUDIO, "master", 1.0), false)
	set_volume("Music", config.get_value(SECTION_AUDIO, "music", 1.0), false)
	set_volume("SFX", config.get_value(SECTION_AUDIO, "sfx", 1.0), false)
	
	# --- General ---
	set_language(config.get_value(SECTION_GENERAL, "language", "es"), false)
	
	# --- Controles ---
	apply_saved_keybinds()
	
	settings_applied.emit()


# --- MÉTODOS DE APLICACIÓN INDIVIDUAL ---

func set_fullscreen(value: bool, auto_save: bool = true) -> void:
	config.set_value(SECTION_VIDEO, "fullscreen", value)
	if value:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if auto_save: save_settings()


func set_resolution(size: Vector2i, auto_save: bool = true) -> void:
	config.set_value(SECTION_VIDEO, "resolution_w", size.x)
	config.set_value(SECTION_VIDEO, "resolution_h", size.y)
	# Solo aplicar resolución si no estamos en fullscreen (o salir de fullscreen)
	var is_fullscreen = config.get_value(SECTION_VIDEO, "fullscreen", true)
	if not is_fullscreen:
		DisplayServer.window_set_size(size)
		# Centrar ventana
		var screen_size = DisplayServer.screen_get_size()
		var window_pos = Vector2i(int(float(screen_size.x - size.x) / 2.0), int(float(screen_size.y - size.y) / 2.0))
		DisplayServer.window_set_position(window_pos)
	if auto_save: save_settings()


func set_fps_limit(fps: int, auto_save: bool = true) -> void:
	config.set_value(SECTION_VIDEO, "fps_limit", fps)
	Engine.max_fps = fps
	if auto_save: save_settings()


func set_volume(bus_name: String, value_linear: float, auto_save: bool = true) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		var db = linear_to_db(value_linear)
		AudioServer.set_bus_volume_db(bus_idx, db)
		config.set_value(SECTION_AUDIO, bus_name.to_lower(), value_linear)
		if auto_save: save_settings()


func set_language(locale: String, auto_save: bool = true) -> void:
	config.set_value(SECTION_GENERAL, "language", locale)
	TranslationServer.set_locale(locale)
	if auto_save: save_settings()


# --- CONTROLES ---

func apply_saved_keybinds() -> void:
	if not config.has_section(SECTION_CONTROLS):
		return
	
	for action in config.get_section_keys(SECTION_CONTROLS):
		var events_data = config.get_value(SECTION_CONTROLS, action)
		if events_data is Array:
			# Borrar eventos actuales
			InputMap.action_erase_events(action)
			# Agregar guardados
			for ev_data in events_data:
				var ev = _deserialize_input_event(ev_data)
				if ev:
					InputMap.action_add_event(action, ev)

func set_keybind(action: String, event: InputEvent) -> void:
	# Reemplazar todos los eventos de la acción con este único evento.
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	
	# Guardar serializado
	var serialized = _serialize_input_event(event)
	config.set_value(SECTION_CONTROLS, action, [serialized])
	save_settings()


func _serialize_input_event(event: InputEvent) -> Dictionary:
	var dict = {}
	if event is InputEventKey:
		dict["type"] = "key"
		dict["keycode"] = event.physical_keycode
	elif event is InputEventMouseButton:
		dict["type"] = "mouse"
		dict["button_index"] = event.button_index
	return dict


func _deserialize_input_event(dict: Dictionary) -> InputEvent:
	if not dict.has("type"): return null
	
	if dict["type"] == "key":
		var ev = InputEventKey.new()
		ev.physical_keycode = dict["keycode"]
		return ev
	elif dict["type"] == "mouse":
		var ev = InputEventMouseButton.new()
		ev.button_index = dict["button_index"]
		return ev
	return null

func get_action_event(action: String) -> InputEvent:
	var events = InputMap.action_get_events(action)
	if events.size() > 0:
		return events[0]
	return null
