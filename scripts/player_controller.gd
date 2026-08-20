class_name PlayerController
extends CharacterBody3D

## Controlador de personaje para juego de supervivencia 3D con vista isométrica (estilo Escape from Duckov).
## Maneja movimiento WASD (relativo a la cámara), apuntado con el mouse y máquina de estados de animación.

# -----------------------------------------------------------------------------
# CONSTANTES Y SEÑALES
# -----------------------------------------------------------------------------
signal attacked(target_position: Vector3)

# Nombres de los estados en el AnimationTree StateMachine
const ANIM_MOVEMENT: StringName = &"Movement"
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

@export_group("Animaciones")
@export var blend_smoothing_speed: float = 12.0 ## Velocidad de interpolación del BlendSpace2D

@export_group("Físicas")
@export var gravity: float = 9.8

@export_group("Referencias de Nodos")
@export var animation_tree: AnimationTree
@export var model_node: Node3D # Nodo 3D que contiene el modelo/esqueleto (opcional, por defecto rota el propio nodo)

@export_group("Mira / Cursor")
@export var enable_custom_crosshair: bool = true
@export var crosshair_texture: Texture2D

@export_group("Equipamiento / Armas")
@export var right_hand_attachment: BoneAttachment3D
@export var weapon_offset_position: Vector3 = Vector3(0.0, 0.0, 0.0):
	set(value):
		weapon_offset_position = value
		_apply_weapon_transform()

@export var weapon_offset_rotation_degrees: Vector3 = Vector3(0.0, 0.0, 0.0):
	set(value):
		weapon_offset_rotation_degrees = value
		_apply_weapon_transform()

@export var weapon_scale: Vector3 = Vector3(1.0, 1.0, 1.0):
	set(value):
		weapon_scale = value
		_apply_weapon_transform()

@export_group("Combate")
@export var attack_duration: float = 0.8 ## Duración del bloqueo de movimiento durante el ataque cuerpo a cuerpo

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
var _current_interactable: PickupItem
var _equipped_weapon_instance: Node3D
var _current_blend_position: Vector2 = Vector2.ZERO
var _attack_timer: float = 0.0


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

	# Conectar con el inventario UI si existe en la escena
	var inventory := get_tree().get_first_node_in_group("inventory_ui") as InventoryUI
	if inventory:
		inventory.item_selected.connect(on_inventory_item_selected)
		on_inventory_item_selected(inventory.get_selected_slot(), inventory.get_selected_item_data())


func _physics_process(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			is_attacking = false

	_update_camera_reference()
	_handle_gravity(delta)
	_handle_aiming(delta)
	_handle_attack_input()
	_handle_movement(delta)
	_update_animations(delta)

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if _current_interactable:
			_current_interactable.pickup(self)


# -----------------------------------------------------------------------------
# GRAVEDAD
# -----------------------------------------------------------------------------
func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0:
			velocity.y = 0.0


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
	# Si se está ejecutando el ataque, bloquear totalmente el desplazamiento y frenar con fricción
	if is_attacking or _attack_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)
		return

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
	if Input.is_action_just_pressed("attack") and not is_attacking and _attack_timer <= 0.0:
		trigger_meele_attack()


func trigger_meele_attack() -> void:
	if not _playback:
		return

	# Usar la duración de ataque configurada (snappy, sin retrasos residuales)
	_attack_timer = attack_duration
	is_attacking = true
	_playback.travel(ANIM_MEELE_ATTACK)
	attacked.emit(aim_position)


# -----------------------------------------------------------------------------
# ACTUALIZACIÓN DEL ANIMATION TREE (BlendSpace2D + StateMachine)
# -----------------------------------------------------------------------------
func _update_animations(delta: float) -> void:
	if not _playback:
		return

	# Si estamos en estado de ataque, mantener reposo en el blend y no sobreescribir con Movement
	if is_attacking or _attack_timer > 0.0:
		_current_blend_position = _current_blend_position.move_toward(Vector2.ZERO, blend_smoothing_speed * delta)
		if animation_tree:
			animation_tree.set("parameters/Movement/blend_position", _current_blend_position)
		return

	var current_node := _playback.get_current_node()

	# Asegurar que el estado activo sea Movement
	if current_node != ANIM_MOVEMENT:
		_playback.travel(ANIM_MOVEMENT)

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var has_movement_input := input_vector.length_squared() > 0.01
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()

	var target_blend := Vector2.ZERO

	if has_movement_input and horizontal_speed > 0.05:
		if movement_mode == MovementMode.CHARACTER_ORIENTED:
			# X = Strafe (-1.0 Izquierda / A, +1.0 Derecha / D)
			# Y = Avance (+1.0 Adelante / W, -1.0 Atrás / S)
			# input_vector.x: -1 (A) a +1 (D)
			# input_vector.y: -1 (W) a +1 (S) -> Invertimos Y para que W sea +1.0
			target_blend = Vector2(input_vector.x, -input_vector.y)
		else:
			# En modo cámara, calcular proyección relativa a la orientación del personaje
			var char_forward := Vector3(sin(model_node.rotation.y), 0.0, cos(model_node.rotation.y)).normalized()
			var char_right := char_forward.cross(Vector3.UP).normalized()
			var move_dir := Vector3(velocity.x, 0.0, velocity.z).normalized()
			var forward_amt := char_forward.dot(move_dir)
			var right_amt := char_right.dot(move_dir)
			target_blend = Vector2(right_amt, forward_amt)

		# Normalizar para diagonales suaves
		if target_blend.length_squared() > 1.0:
			target_blend = target_blend.normalized()

	# Interpolar suavemente hacia la posición objetivo en el BlendSpace2D
	_current_blend_position = _current_blend_position.move_toward(target_blend, blend_smoothing_speed * delta)

	# Actualizar el parámetro blend_position del BlendSpace2D
	if animation_tree:
		animation_tree.set("parameters/Movement/blend_position", _current_blend_position)


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
		"interact": [KEY_F],
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
# SISTEMA DE INTERACCIÓN Y EQUIPAMIENTO DE ARMAS
# -----------------------------------------------------------------------------
func set_current_interactable(item: PickupItem) -> void:
	_current_interactable = item


func get_current_interactable() -> PickupItem:
	return _current_interactable


## Busca o crea dinámicamente un nodo BoneAttachment3D en el hueso de la mano derecha
func _get_or_create_hand_attachment() -> BoneAttachment3D:
	if is_instance_valid(right_hand_attachment):
		return right_hand_attachment

	# Buscar Skeleton3D dentro del personaje
	var skeleton: Skeleton3D = find_child("Skeleton3D", true, false) as Skeleton3D
	if not skeleton:
		push_warning("Skeleton3D no encontrado en el personaje para anclar arma.")
		return null

	# Comprobar si ya existe un BoneAttachment3D para la mano derecha
	for child in skeleton.get_children():
		if child is BoneAttachment3D:
			var bone_att := child as BoneAttachment3D
			if bone_att.bone_name == "mixamorig:RightHand" or bone_att.bone_name == "RightHand" or bone_att.name == "RightHandAttachment":
				right_hand_attachment = bone_att
				if right_hand_attachment.bone_idx < 0:
					right_hand_attachment.bone_idx = skeleton.find_bone(right_hand_attachment.bone_name)
				return right_hand_attachment

	# Buscar el índice del hueso en el Skeleton3D
	var bone_name_target := "mixamorig:RightHand"
	var bone_index := skeleton.find_bone(bone_name_target)
	if bone_index == -1:
		for alt in ["RightHand", "mixamorig_RightHand", "Right_Hand", "Hand.R"]:
			bone_index = skeleton.find_bone(alt)
			if bone_index != -1:
				bone_name_target = alt
				break

	if bone_index == -1 and skeleton.get_bone_count() > 22:
		bone_index = 22
		bone_name_target = skeleton.get_bone_name(22)

	# Crear BoneAttachment3D dinámicamente con nombre y bone_idx asignados
	var attachment := BoneAttachment3D.new()
	attachment.name = "RightHandAttachment"
	attachment.bone_name = bone_name_target
	if bone_index >= 0:
		attachment.bone_idx = bone_index

	skeleton.add_child(attachment)
	right_hand_attachment = attachment
	return right_hand_attachment


## Equipa un arma instanciando su escena en el BoneAttachment3D de la mano derecha
func equip_right_hand(weapon_scene: PackedScene) -> void:
	var attachment := _get_or_create_hand_attachment()
	if not attachment:
		push_error("No se pudo obtener el BoneAttachment3D de la mano derecha.")
		return

	# Limpiar cualquier arma previa equipada en la mano
	if is_instance_valid(_equipped_weapon_instance):
		_equipped_weapon_instance.queue_free()

	for child in attachment.get_children():
		child.queue_free()

	# Instanciar el modelo del arma
	var weapon: Node3D = weapon_scene.instantiate() as Node3D
	if weapon:
		attachment.add_child(weapon)
		_equipped_weapon_instance = weapon
		_apply_weapon_transform()


## Aplica posición, rotación y escala al arma actualmente equipada
func _apply_weapon_transform() -> void:
	if is_instance_valid(_equipped_weapon_instance):
		_equipped_weapon_instance.position = weapon_offset_position
		_equipped_weapon_instance.rotation_degrees = weapon_offset_rotation_degrees
		_equipped_weapon_instance.scale = weapon_scale


## Desequipa y destruye el arma actualmente montada en la mano derecha
func unequip_right_hand() -> void:
	if is_instance_valid(_equipped_weapon_instance):
		_equipped_weapon_instance.queue_free()
		_equipped_weapon_instance = null

	var attachment := _get_or_create_hand_attachment()
	if attachment:
		for child in attachment.get_children():
			child.queue_free()


## Sincroniza el arma equipada con el slot del inventario seleccionado
func on_inventory_item_selected(_slot_index: int, item_data: Dictionary) -> void:
	if item_data.has("weapon_scene") and item_data["weapon_scene"] != null:
		equip_right_hand(item_data["weapon_scene"])
	else:
		unequip_right_hand()


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
