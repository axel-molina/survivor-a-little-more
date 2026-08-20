extends Button

## Script para botones de asignación de teclas.
## Al hacer clic, espera la próxima entrada del usuario y la asigna a la acción especificada.

@export var action_name: String = ""

var is_waiting_for_input: bool = false
var default_text: String = ""

signal input_rebound(action: String, event: InputEvent)


func _ready() -> void:
	toggle_mode = true
	toggled.connect(_on_toggled)
	_update_text()


func _on_toggled(p_toggled: bool) -> void:
	if p_toggled:
		is_waiting_for_input = true
		text = tr("BTN_PRESS_KEY")
		# Cambiar color o estilo visual si se desea
		modulate = Color(1.5, 1.5, 0.5) # Amarillo brillante temporal
	else:
		is_waiting_for_input = false
		_update_text()
		modulate = Color.WHITE


func _input(event: InputEvent) -> void:
	if not is_waiting_for_input:
		return
		
	# Capturar teclas y clics de ratón
	if event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_ESCAPE:
			# Si presiona Escape, cancelar asignación
			button_pressed = false
			get_viewport().set_input_as_handled()
			return
			
		_apply_new_input(event)
		
	elif event is InputEventMouseButton and event.pressed:
		_apply_new_input(event)


func _apply_new_input(event: InputEvent) -> void:
	SettingsManager.set_keybind(action_name, event)
	is_waiting_for_input = false
	button_pressed = false
	_update_text()
	input_rebound.emit(action_name, event)
	get_viewport().set_input_as_handled()


func _update_text() -> void:
	var ev = SettingsManager.get_action_event(action_name)
	if ev:
		if ev is InputEventKey:
			text = OS.get_keycode_string(ev.physical_keycode)
		elif ev is InputEventMouseButton:
			text = "Mouse " + str(ev.button_index)
		else:
			text = "..."
	else:
		text = "N/A"
