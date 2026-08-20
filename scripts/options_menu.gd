extends CanvasLayer

@onready var bg_rect: ColorRect = $ColorRect
@onready var tabs: TabContainer = $CenterContainer/PanelContainer/HBoxContainer/TabContainer

@onready var btn_video: Button = $CenterContainer/PanelContainer/HBoxContainer/Sidebar/BtnVideo
@onready var btn_audio: Button = $CenterContainer/PanelContainer/HBoxContainer/Sidebar/BtnAudio
@onready var btn_general: Button = $CenterContainer/PanelContainer/HBoxContainer/Sidebar/BtnGeneral
@onready var btn_controls: Button = $CenterContainer/PanelContainer/HBoxContainer/Sidebar/BtnControls
@onready var btn_back: Button = $CenterContainer/PanelContainer/HBoxContainer/Sidebar/BtnBack

# Controles Video
@onready var chk_fullscreen: CheckButton = $CenterContainer/PanelContainer/HBoxContainer/TabContainer/VideoTab/Grid/ChkFullscreen
@onready var opt_resolution: OptionButton = $CenterContainer/PanelContainer/HBoxContainer/TabContainer/VideoTab/Grid/OptResolution
@onready var opt_fps: OptionButton = $CenterContainer/PanelContainer/HBoxContainer/TabContainer/VideoTab/Grid/OptFPS

# Controles Audio
@onready var sld_master: HSlider = $CenterContainer/PanelContainer/HBoxContainer/TabContainer/AudioTab/VBox/SldMaster
@onready var sld_music: HSlider = $CenterContainer/PanelContainer/HBoxContainer/TabContainer/AudioTab/VBox/SldMusic
@onready var sld_sfx: HSlider = $CenterContainer/PanelContainer/HBoxContainer/TabContainer/AudioTab/VBox/SldSFX

# Controles General
@onready var opt_language: OptionButton = $CenterContainer/PanelContainer/HBoxContainer/TabContainer/GeneralTab/VBox/OptLanguage

# SFX
@export var hover_sfx: AudioStream = preload("res://sfx/ui/hover_sound.mp3")
@export var submit_sfx: AudioStream = preload("res://sfx/ui/submit_sound.wav")
var _hover_player: AudioStreamPlayer
var _submit_player: AudioStreamPlayer

var available_resolutions = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

signal closed


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_sfx()
	_populate_dropdowns()
	_load_current_values()
	
	# Ocultar tabs (las pestañas visuales nativas)
	tabs.tabs_visible = false
	
	# Conexiones Sidebar
	btn_video.pressed.connect(func(): _switch_tab(0))
	btn_audio.pressed.connect(func(): _switch_tab(1))
	btn_general.pressed.connect(func(): _switch_tab(2))
	btn_controls.pressed.connect(func(): _switch_tab(3))
	btn_back.pressed.connect(close)
	
	# Conexiones UI Video
	chk_fullscreen.toggled.connect(_on_fullscreen_toggled)
	opt_resolution.item_selected.connect(_on_resolution_selected)
	opt_fps.item_selected.connect(_on_fps_selected)
	
	# Conexiones UI Audio
	sld_master.value_changed.connect(func(v): SettingsManager.set_volume("Master", v))
	sld_music.value_changed.connect(func(v): SettingsManager.set_volume("Music", v))
	sld_sfx.value_changed.connect(func(v): SettingsManager.set_volume("SFX", v))
	
	# Conexiones UI General
	opt_language.item_selected.connect(_on_language_selected)
	
	# Suscribirse al cambio de idioma (para actualizar textos dinámicamente si es necesario)
	SettingsManager.settings_applied.connect(_on_settings_applied)
	
	# Iniciar en pestaña de video
	_switch_tab(0)


func _setup_sfx() -> void:
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
	
	# Conectar hover
	var all_buttons = [btn_video, btn_audio, btn_general, btn_controls, btn_back, chk_fullscreen]
	for b in all_buttons:
		b.mouse_entered.connect(_hover_player.play)
		b.focus_entered.connect(_hover_player.play)
		b.pressed.connect(_submit_player.play)


func _populate_dropdowns() -> void:
	# Resoluciones
	opt_resolution.clear()
	var screen_res = DisplayServer.screen_get_size()
	var added_current = false
	
	for i in range(available_resolutions.size()):
		var res = available_resolutions[i]
		if res.x <= screen_res.x and res.y <= screen_res.y:
			opt_resolution.add_item(str(res.x) + "x" + str(res.y))
			opt_resolution.set_item_metadata(i, res)
			if res == screen_res: added_current = true
			
	if not added_current and not available_resolutions.has(screen_res):
		opt_resolution.add_item(str(screen_res.x) + "x" + str(screen_res.y))
		opt_resolution.set_item_metadata(opt_resolution.item_count - 1, screen_res)

	# FPS
	opt_fps.clear()
	opt_fps.add_item("30", 0)
	opt_fps.set_item_metadata(0, 30)
	opt_fps.add_item("60", 1)
	opt_fps.set_item_metadata(1, 60)
	opt_fps.add_item("120", 2)
	opt_fps.set_item_metadata(2, 120)
	opt_fps.add_item("144", 3)
	opt_fps.set_item_metadata(3, 144)
	opt_fps.add_item("Ilimitado", 4)
	opt_fps.set_item_metadata(4, 0)

	# Idioma
	opt_language.clear()
	opt_language.add_item("Español", 0)
	opt_language.set_item_metadata(0, "es")
	opt_language.add_item("English", 1)
	opt_language.set_item_metadata(1, "en")


func _load_current_values() -> void:
	var c = SettingsManager.config
	
	# Video
	chk_fullscreen.button_pressed = c.get_value(SettingsManager.SECTION_VIDEO, "fullscreen", true)
	var res_w = c.get_value(SettingsManager.SECTION_VIDEO, "resolution_w", 1920)
	var res_h = c.get_value(SettingsManager.SECTION_VIDEO, "resolution_h", 1080)
	var current_res = Vector2i(res_w, res_h)
	for i in range(opt_resolution.item_count):
		if opt_resolution.get_item_metadata(i) == current_res:
			opt_resolution.select(i)
			break
			
	var fps = c.get_value(SettingsManager.SECTION_VIDEO, "fps_limit", 60)
	for i in range(opt_fps.item_count):
		if opt_fps.get_item_metadata(i) == fps:
			opt_fps.select(i)
			break
			
	# Audio
	sld_master.value = c.get_value(SettingsManager.SECTION_AUDIO, "master", 1.0)
	sld_music.value = c.get_value(SettingsManager.SECTION_AUDIO, "music", 1.0)
	sld_sfx.value = c.get_value(SettingsManager.SECTION_AUDIO, "sfx", 1.0)
	
	# General
	var lang = c.get_value(SettingsManager.SECTION_GENERAL, "language", "es")
	for i in range(opt_language.item_count):
		if opt_language.get_item_metadata(i) == lang:
			opt_language.select(i)
			break


func _switch_tab(index: int) -> void:
	tabs.current_tab = index


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	SettingsManager.set_fullscreen(toggled_on)
	opt_resolution.disabled = toggled_on # No se puede cambiar resolución si es pantalla completa


func _on_resolution_selected(index: int) -> void:
	var res = opt_resolution.get_item_metadata(index) as Vector2i
	SettingsManager.set_resolution(res)


func _on_fps_selected(index: int) -> void:
	var fps = opt_fps.get_item_metadata(index) as int
	SettingsManager.set_fps_limit(fps)


func _on_language_selected(index: int) -> void:
	var lang = opt_language.get_item_metadata(index) as String
	SettingsManager.set_language(lang)


func _on_settings_applied() -> void:
	# Podríamos forzar actualización de UI si algo cambia externamente
	pass


func close() -> void:
	visible = false
	closed.emit()
	queue_free()

func open() -> void:
	visible = true
