class_name PlayerController
extends CharacterBody3D

## Controlador de personaje para juego de supervivencia 3D con vista isométrica (estilo Escape from Duckov).
## Maneja movimiento WASD (relativo a la cámara), apuntado con el mouse y máquina de estados de animación.

# -----------------------------------------------------------------------------
# CONSTANTES Y SEÑALES
# -----------------------------------------------------------------------------
signal attacked(target_position: Vector3)

# Nombres exactos de las animaciones en el AnimationTree StateMachine
const ANIM_IDLE: StringName = &"Idle"
const ANIM_RUN: StringName = &"Run"
const ANIM_BACKWARD_RUN: StringName = &"Backward Run"
const ANIM_STRAFE_LEFT: StringName = &"Strafe Left"
const ANIM_STRAFE_RIGHT: StringName = &"Strafe Right"
const ANIM_MEELE_ATTACK: StringName = &"Meele Attack"

enum MovementMode {
	CHARACTER_ORIENTED, ## W avanza hacia donde mira el personaje, S retrocede, A/D strafe izquierda/derecha
	CAMERA_ORIENTED     ## W avanza hacia arriba en pantalla relativo a la cámara
}

@export_group("Movimiento")
@export var movement_mode: MovementMode = MovementMode.CHARACTER_ORIENTED
@export var move_speed: float = 6.0
@export var acceleration: float = 20.0
@export var friction: float = 18.0
@export var rotation_speed: float = 20.0 # Velocidad de giro hacia el mouse (0 = instantáneo)

@export_group("Físicas")
@export var gravity: float = 9.8

@export_group("Referencias de Nodos")
@export var animation_tree: AnimationTree
@export var model_node: Node3D # Nodo 3D que contiene el modelo/esqueleto (opcional, por defecto rota el propio nodo)

@export_group("Mira / Cursor")
@export var enable_custom_crosshair: bool = true
@export var crosshair_texture: Texture2D

# -----------------------------------------------------------------------------
# VARIABLES PÚBLICAS Y DE APUNTADO (Para armas / mira en el futuro)
# -----------------------------------------------------------------------------
var aim_position: Vector3 = Vector3.ZERO
var aim_direction: Vector3 = Vector3.FORWARD
var is_attacking: bool = false

# -----------------------------------------------------------------------------
# VARIABLES PRIVADAS
# -----------------------------------------------------------------------------
var _playback: AnimationNodeStateMachinePlayback
var _camera: Camera3D


func _ready() -> void:
	# Asegurar que las acciones de entrada (WASD, ataque) existan automáticamente
	_setup_default_inputs()
	
	# Buscar AnimationTree si no se asignó en el inspector
	if not animation_tree:
		animation_tree = get_node_or_null("AnimationPlayer/AnimationTree") as AnimationTree
		if not animation_tree:
			animation_tree = find_child("AnimationTree", true, false) as AnimationTree

	if animation_tree:
		animation_tree.active = true
		_playback = animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
		if not _playback:
			push_warning("No se pudo obtener AnimationNodeStateMachinePlayback de AnimationTree.")
	else:
		push_warning("AnimationTree no encontrado en el personaje.")

	# Si no se definió nodo modelo independiente, se utiliza este mismo nodo para rotar
	if not model_node:
		model_node = self

	# Configurar el cursor personalizado como mira
	_setup_custom_crosshair()


func _physics_process(delta: float) -> void:
	_update_camera_reference()
	_handle_gravity(delta)
	_handle_aiming(delta)
	_handle_movement(delta)
	_handle_attack_input()
	_update_animations()

	move_and_slide()


# -----------------------------------------------------------------------------
# GRAVEDAD
# -----------------------------------------------------------------------------
func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0:
			velocity.y = -0.1 # Pequeña fuerza hacia abajo para mantener contacto con el suelo


# -----------------------------------------------------------------------------
# APUNTADO Y ROTACIÓN CON EL MOUSE
# -----------------------------------------------------------------------------
func _handle_aiming(delta: float) -> void:
	if not _camera:
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := _camera.project_ray_origin(mouse_pos)
	var ray_normal := _camera.project_ray_normal(mouse_pos)

	# Intersección del rayo de la cámara con el plano horizontal a la altura del personaje
	var ground_plane := Plane(Vector3.UP, global_position.y)
	var intersection = ground_plane.intersects_ray(ray_origin, ray_normal)

	if intersection != null:
		aim_position = intersection
		var dir_to_target := (aim_position - global_position)
		dir_to_target.y = 0.0

		if dir_to_target.length_squared() > 0.001:
			aim_direction = dir_to_target.normalized()

			# Calcular el ángulo objetivo en el eje Y
			var target_angle_y := atan2(aim_direction.x, aim_direction.z)

			if rotation_speed > 0.0:
				# Rotación suave
				model_node.rotation.y = lerp_angle(model_node.rotation.y, target_angle_y, rotation_speed * delta)
			else:
				# Rotación directa/instantánea
				model_node.rotation.y = target_angle_y


# -----------------------------------------------------------------------------
# MOVIMIENTO WASD (Orientado al Personaje o a la Cámara)
# -----------------------------------------------------------------------------
func _handle_movement(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var move_direction := Vector3.ZERO

	if movement_mode == MovementMode.CHARACTER_ORIENTED:
		# Adelante es exactamente hacia donde mira el personaje/modelo
		var char_forward := Vector3(sin(model_node.rotation.y), 0.0, cos(model_node.rotation.y)).normalized()
		var char_right := char_forward.cross(Vector3.UP).normalized()

		# W (input_vector.y = -1) -> char_forward
		# S (input_vector.y = 1) -> -char_forward
		# D (input_vector.x = 1) -> char_right (derecha)
		# A (input_vector.x = -1) -> -char_right (izquierda)
		move_direction = (char_forward * -input_vector.y + char_right * input_vector.x).normalized()
	else:
		# Movimiento relativo a la cámara isométrica
		if _camera:
			var cam_forward := -_camera.global_transform.basis.z
			cam_forward.y = 0.0
			cam_forward = cam_forward.normalized()

			var cam_right := _camera.global_transform.basis.x
			cam_right.y = 0.0
			cam_right = cam_right.normalized()

			move_direction = (cam_right * input_vector.x + cam_forward * -input_vector.y).normalized()
		else:
			move_direction = Vector3(input_vector.x, 0.0, input_vector.y).normalized()

	# Aplicar aceleración o fricción
	if move_direction.length_squared() > 0.01:
		var target_vel := move_direction * move_speed
		velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)


# -----------------------------------------------------------------------------
# ENTRADA DE ATAQUE / ACCIÓN
# -----------------------------------------------------------------------------
func _handle_attack_input() -> void:
	if Input.is_action_just_pressed("attack") and not is_attacking:
		trigger_meele_attack()


func trigger_meele_attack() -> void:
	if not _playback:
		return

	is_attacking = true
	_playback.travel(ANIM_MEELE_ATTACK)
	attacked.emit(aim_position)


# -----------------------------------------------------------------------------
# ACTUALIZACIÓN DEL ANIMATION TREE
# -----------------------------------------------------------------------------
func _update_animations() -> void:
	if not _playback:
		return

	var current_node := _playback.get_current_node()

	# Si estamos en estado de ataque, verificar si ya terminó
	if is_attacking:
		if current_node != ANIM_MEELE_ATTACK:
			is_attacking = false
		else:
			return # Dejar que termine la animación de ataque

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var has_movement_input := input_vector.length_squared() > 0.01
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()

	# Si no hay entrada de movimiento activa o la velocidad es mínima, transicionar directamente a Idle
	if not has_movement_input or horizontal_speed <= 0.15:
		if current_node != ANIM_IDLE:
			_playback.travel(ANIM_IDLE)
		return

	# Si hay entrada de movimiento activa y el personaje se está desplazando:
	var target_anim := ANIM_RUN

	if movement_mode == MovementMode.CHARACTER_ORIENTED:
		# En modo orientado al personaje:
		# W o diagonales hacia adelante -> Run
		# S o diagonales hacia atrás -> Backward Run
		# A (lateral izquierda) -> Strafe Left
		# D (lateral derecha) -> Strafe Right
		if input_vector.y < -0.3:
			target_anim = ANIM_RUN
		elif input_vector.y > 0.3:
			target_anim = ANIM_BACKWARD_RUN
		elif input_vector.x < -0.1:
			target_anim = ANIM_STRAFE_LEFT
		elif input_vector.x > 0.1:
			target_anim = ANIM_STRAFE_RIGHT
	else:
		# En modo cámara, evaluar respecto a la orientación relativa del personaje
		var char_forward := Vector3(sin(model_node.rotation.y), 0.0, cos(model_node.rotation.y)).normalized()
		var char_right := char_forward.cross(Vector3.UP).normalized()
		var move_dir := Vector3(velocity.x, 0.0, velocity.z).normalized()
		var forward_dot := char_forward.dot(move_dir)
		var right_dot := char_right.dot(move_dir)

		if forward_dot > 0.5:
			target_anim = ANIM_RUN
		elif forward_dot < -0.5:
			target_anim = ANIM_BACKWARD_RUN
		elif right_dot < -0.3:
			target_anim = ANIM_STRAFE_LEFT
		elif right_dot > 0.3:
			target_anim = ANIM_STRAFE_RIGHT

	if current_node != target_anim:
		_playback.travel(target_anim)


# -----------------------------------------------------------------------------
# REFERENCIA DE CÁMARA
# -----------------------------------------------------------------------------
func _update_camera_reference() -> void:
	if not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()


# -----------------------------------------------------------------------------
# CONFIGURACIÓN AUTOMÁTICA DE ACCIONES DE ENTRADA (Fallback)
# -----------------------------------------------------------------------------
func _setup_default_inputs() -> void:
	var default_keys: Dictionary = {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_forward": [KEY_W, KEY_UP],
		"move_backward": [KEY_S, KEY_DOWN],
	}

	for action in default_keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for keycode in default_keys[action]:
				var event := InputEventKey.new()
				event.physical_keycode = keycode
				InputMap.action_add_event(action, event)

	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", mouse_event)


# -----------------------------------------------------------------------------
# CONFIGURACIÓN DEL CURSOR / MIRA
# -----------------------------------------------------------------------------
func _setup_custom_crosshair() -> void:
	if not enable_custom_crosshair:
		return

	if crosshair_texture:
		var size := crosshair_texture.get_size()
		var hotspot := size / 2.0
		Input.set_custom_mouse_cursor(crosshair_texture, Input.CURSOR_ARROW, hotspot)
	elif ResourceLoader.exists("res://assets/Mira/punto-de-mira-32.png"):
		var tex: Texture2D = load("res://assets/Mira/punto-de-mira-32.png")
		if tex:
			Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, tex.get_size() / 2.0)
	elif ResourceLoader.exists("res://assets/Mira/punto-de-mira-64.png"):
		var tex: Texture2D = load("res://assets/Mira/punto-de-mira-64.png")
		if tex:
			Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, tex.get_size() / 2.0)
