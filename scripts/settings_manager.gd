extends Node

const SETTINGS_FILE_PATH = "user://settings.cfg"

var config := ConfigFile.new()

# Claves de configuración
const SECTION_VIDEO = "video"
const SECTION_AUDIO = "audio"
const SECTION_GENERAL = "general"
const SECTION_CONTROLS = "controls"

signal settings_applied


var _fps_layer: CanvasLayer
var _fps_label: Label
var _show_fps: bool = false
var _fps_update_timer: float = 0.0


func _ready() -> void:
	# Este nodo no debe pausarse, para que las opciones puedan cambiarse
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_fps_counter()
	load_settings()


func _process(delta: float) -> void:
	if _show_fps and is_instance_valid(_fps_label):
		_fps_update_timer += delta
		if _fps_update_timer >= 0.1:
			_fps_update_timer = 0.0
			_fps_label.text = "%d FPS" % Engine.get_frames_per_second()


func _setup_fps_counter() -> void:
	_fps_layer = CanvasLayer.new()
	_fps_layer.name = "FPSOverlay"
	_fps_layer.layer = 128
	_fps_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var margin := MarginContainer.new()
	margin.anchors_preset = Control.PRESET_TOP_RIGHT
	margin.anchor_left = 1.0
	margin.anchor_right = 1.0
	margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	
	_fps_label = Label.new()
	_fps_label.name = "FPSLabel"
	_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if ResourceLoader.exists("res://font/inika/Inika-Bold.ttf"):
		var font := load("res://font/inika/Inika-Bold.ttf") as Font
		if font:
			_fps_label.add_theme_font_override("font", font)
			
	_fps_label.add_theme_font_size_override("font_size", 14)
	_fps_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.45, 0.95))
	_fps_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_fps_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	_fps_label.add_theme_constant_override("outline_size", 5)
	_fps_label.add_theme_constant_override("shadow_offset_x", 1)
	_fps_label.add_theme_constant_override("shadow_offset_y", 1)
	_fps_label.text = "60 FPS"
	
	margin.add_child(_fps_label)
	_fps_layer.add_child(margin)
	add_child(_fps_layer)
	
	_fps_layer.visible = _show_fps


func load_settings() -> void:
	_ensure_default_input_map()
	var err = config.load(SETTINGS_FILE_PATH)
	if err != OK:
		# Si no existe, configurar valores por defecto
		_setup_default_settings()
		save_settings()
	
	apply_all_settings()


func _ensure_default_input_map() -> void:
	var default_keys: Dictionary = {
		"move_forward": KEY_W,
		"move_backward": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"interact": KEY_F,
		"slot_1": KEY_1,
		"slot_2": KEY_2,
		"slot_3": KEY_3,
		"slot_4": KEY_4,
		"slot_5": KEY_5,
		"slot_6": KEY_6,
		"ui_cancel": KEY_ESCAPE
	}
	for action in default_keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var ev := InputEventKey.new()
			ev.physical_keycode = default_keys[action]
			InputMap.action_add_event(action, ev)
		elif InputMap.action_get_events(action).is_empty():
			var ev := InputEventKey.new()
			ev.physical_keycode = default_keys[action]
			InputMap.action_add_event(action, ev)

	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", mouse_event)
	elif InputMap.action_get_events("attack").is_empty():
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", mouse_event)


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
	config.set_value(SECTION_VIDEO, "show_fps", false)
	
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
	
	var show_fps = config.get_value(SECTION_VIDEO, "show_fps", false)
	set_show_fps(show_fps, false)
	
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

func set_show_fps(value: bool, auto_save: bool = true) -> void:
	_show_fps = value
	config.set_value(SECTION_VIDEO, "show_fps", value)
	if is_instance_valid(_fps_layer):
		_fps_layer.visible = value
	if auto_save: save_settings()


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
		dict["keycode"] = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	elif event is InputEventMouseButton:
		dict["type"] = "mouse"
		dict["button_index"] = event.button_index
	return dict


func _deserialize_input_event(dict: Dictionary) -> InputEvent:
	if not dict.has("type"): return null
	
	if dict["type"] == "key":
		var ev = InputEventKey.new()
		ev.physical_keycode = dict["keycode"]
		ev.keycode = dict["keycode"]
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
