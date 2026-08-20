extends CanvasLayer

@onready var blur_overlay: ColorRect = $BlurOverlay
@onready var panel_container: PanelContainer = $CenterContainer/PanelContainer
@onready var tabs: TabContainer = $CenterContainer/PanelContainer/MainLayout/ContentLayout/TabContainer

@onready var btn_video: Button = $CenterContainer/PanelContainer/MainLayout/ContentLayout/Sidebar/BtnVideo
@onready var btn_audio: Button = $CenterContainer/PanelContainer/MainLayout/ContentLayout/Sidebar/BtnAudio
@onready var btn_general: Button = $CenterContainer/PanelContainer/MainLayout/ContentLayout/Sidebar/BtnGeneral
@onready var btn_controls: Button = $CenterContainer/PanelContainer/MainLayout/ContentLayout/Sidebar/BtnControls
@onready var btn_back: Button = $CenterContainer/PanelContainer/MainLayout/ContentLayout/Sidebar/BtnBack

# Controles Video
@onready var chk_fullscreen: CheckButton = $CenterContainer/PanelContainer/MainLayout/ContentLayout/TabContainer/VideoTab/Grid/ChkFullscreen
@onready var opt_resolution: OptionButton = $CenterContainer/PanelContainer/MainLayout/ContentLayout/TabContainer/VideoTab/Grid/OptResolution
@onready var opt_fps: OptionButton = $CenterContainer/PanelContainer/MainLayout/ContentLayout/TabContainer/VideoTab/Grid/OptFPS

# Controles Audio
@onready var sld_master: HSlider = $CenterContainer/PanelContainer/MainLayout/ContentLayout/TabContainer/AudioTab/VBox/MasterGroup/SldMaster
@onready var val_master: Label = $CenterContainer/PanelContainer/MainLayout/ContentLayout/TabContainer/AudioTab/VBox/MasterGroup/HeaderMaster/ValMaster

@onready var sld_music: HSlider = $CenterContainer/PanelContainer/MainLayout/ContentLayout/TabContainer/AudioTab/VBox/MusicGroup/SldMusic
@onready var val_music: Label = $CenterContainer/PanelContainer/MainLayout/ContentLayout/TabContainer/AudioTab/VBox/MusicGroup/HeaderMusic/ValMusic

@onready var sld_sfx: HSlider = $CenterContainer/PanelContainer/MainLayout/ContentLayout/TabContainer/AudioTab/VBox/SFXGroup/SldSFX
@onready var val_sfx: Label = $CenterContainer/PanelContainer/MainLayout/ContentLayout/TabContainer/AudioTab/VBox/SFXGroup/HeaderSFX/ValSFX

# Controles General
@onready var opt_language: OptionButton = $CenterContainer/PanelContainer/MainLayout/ContentLayout/TabContainer/GeneralTab/VBox/HBoxLang/OptLanguage

# SFX
@export var hover_sfx: AudioStream = preload("res://sfx/ui/hover_sound.mp3")
@export var submit_sfx: AudioStream = preload("res://sfx/ui/submit_sound.wav")
var _hover_player: AudioStreamPlayer
var _submit_player: AudioStreamPlayer

var _tab_buttons: Array[Button] = []

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
	
	_tab_buttons = [btn_video, btn_audio, btn_general, btn_controls]
	
	_setup_sfx()
	_populate_dropdowns()
	_load_current_values()
	
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
	sld_master.value_changed.connect(_on_master_volume_changed)
	sld_music.value_changed.connect(_on_music_volume_changed)
	sld_sfx.value_changed.connect(_on_sfx_volume_changed)
	
	# Conexiones UI General
	opt_language.item_selected.connect(_on_language_selected)
	
	# Iniciar en pestaña de video
	_switch_tab(0)
	
	# Animación de entrada suave
	_animate_open()


func _animate_open() -> void:
	panel_container.modulate.a = 0.0
	panel_container.scale = Vector2(0.96, 0.96)
	panel_container.pivot_offset = panel_container.size / 2.0
	
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel_container, "modulate:a", 1.0, 0.2)
	tween.tween_property(panel_container, "scale", Vector2.ONE, 0.2)


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
	
	_connect_buttons_recursive(panel_container)


func _connect_buttons_recursive(node: Node) -> void:
	if node is Button:
		node.mouse_entered.connect(_play_hover)
		node.focus_entered.connect(_play_hover)
		node.pressed.connect(_play_submit)
	for child in node.get_children():
		_connect_buttons_recursive(child)


func _play_hover() -> void:
	if _hover_player and hover_sfx:
		_hover_player.play()


func _play_submit() -> void:
	if _submit_player and submit_sfx:
		_submit_player.play()


func _populate_dropdowns() -> void:
	# Resoluciones
	opt_resolution.clear()
	var screen_res = DisplayServer.screen_get_size()
	var added_current = false
	
	for i in range(available_resolutions.size()):
		var res = available_resolutions[i]
		if res.x <= screen_res.x and res.y <= screen_res.y:
			opt_resolution.add_item(str(res.x) + " x " + str(res.y))
			opt_resolution.set_item_metadata(i, res)
			if res == screen_res:
				added_current = true
			
	if not added_current and not available_resolutions.has(screen_res):
		opt_resolution.add_item(str(screen_res.x) + " x " + str(screen_res.y))
		opt_resolution.set_item_metadata(opt_resolution.item_count - 1, screen_res)

	# FPS
	opt_fps.clear()
	opt_fps.add_item("30 FPS", 0)
	opt_fps.set_item_metadata(0, 30)
	opt_fps.add_item("60 FPS", 1)
	opt_fps.set_item_metadata(1, 60)
	opt_fps.add_item("120 FPS", 2)
	opt_fps.set_item_metadata(2, 120)
	opt_fps.add_item("144 FPS", 3)
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
	var is_fs = c.get_value(SettingsManager.SECTION_VIDEO, "fullscreen", true)
	chk_fullscreen.button_pressed = is_fs
	opt_resolution.disabled = is_fs
	
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
	var m_vol = c.get_value(SettingsManager.SECTION_AUDIO, "master", 1.0)
	sld_master.value = m_vol
	val_master.text = "%d%%" % int(round(m_vol * 100.0))
	
	var mu_vol = c.get_value(SettingsManager.SECTION_AUDIO, "music", 1.0)
	sld_music.value = mu_vol
	val_music.text = "%d%%" % int(round(mu_vol * 100.0))
	
	var sfx_vol = c.get_value(SettingsManager.SECTION_AUDIO, "sfx", 1.0)
	sld_sfx.value = sfx_vol
	val_sfx.text = "%d%%" % int(round(sfx_vol * 100.0))
	
	# General
	var lang = c.get_value(SettingsManager.SECTION_GENERAL, "language", "es")
	for i in range(opt_language.item_count):
		if opt_language.get_item_metadata(i) == lang:
			opt_language.select(i)
			break


func _switch_tab(index: int) -> void:
	tabs.current_tab = index
	
	# Actualizar estilos visuales de botones laterales
	for i in range(_tab_buttons.size()):
		var btn = _tab_buttons[i]
		if i == index:
			btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45, 1.0))
		else:
			btn.remove_theme_color_override("font_color")


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	SettingsManager.set_fullscreen(toggled_on)
	opt_resolution.disabled = toggled_on


func _on_resolution_selected(index: int) -> void:
	var res = opt_resolution.get_item_metadata(index) as Vector2i
	SettingsManager.set_resolution(res)


func _on_fps_selected(index: int) -> void:
	var fps = opt_fps.get_item_metadata(index) as int
	SettingsManager.set_fps_limit(fps)


func _on_master_volume_changed(value: float) -> void:
	val_master.text = "%d%%" % int(round(value * 100.0))
	SettingsManager.set_volume("Master", value)


func _on_music_volume_changed(value: float) -> void:
	val_music.text = "%d%%" % int(round(value * 100.0))
	SettingsManager.set_volume("Music", value)


func _on_sfx_volume_changed(value: float) -> void:
	val_sfx.text = "%d%%" % int(round(value * 100.0))
	SettingsManager.set_volume("SFX", value)


func _on_language_selected(index: int) -> void:
	var lang = opt_language.get_item_metadata(index) as String
	SettingsManager.set_language(lang)


func close() -> void:
	_submit_player.play()
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(panel_container, "modulate:a", 0.0, 0.15)
	tween.tween_property(panel_container, "scale", Vector2(0.95, 0.95), 0.15)
	await tween.finished
	visible = false
	closed.emit()
	queue_free()
