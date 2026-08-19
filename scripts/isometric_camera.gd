class_name IsometricCamera
extends Camera3D

## Cámara para vista isométrica suave (estilo Escape from Duckov / Project Zomboid).
## Sigue al objetivo (jugador) con interpolación suave y permite ajuste de zoom con la rueda del mouse.

# -----------------------------------------------------------------------------
# VARIABLES EXPORTADAS
# -----------------------------------------------------------------------------
@export var target: Node3D
@export var target_node_path: NodePath

@export_group("Posición Isométrica")
## Offset relativo al objetivo (X=10, Y=14, Z=10 crea un ángulo isométrico clásico a 45 grados)
@export var isometric_offset: Vector3 = Vector3(10.0, 14.0, 10.0)
@export var follow_speed: float = 6.0

@export_group("Zoom")
@export var enable_zoom: bool = true
@export var zoom_speed: float = 1.0
@export var min_zoom_scale: float = 0.5
@export var max_zoom_scale: float = 2.0

# -----------------------------------------------------------------------------
# VARIABLES PRIVADAS
# -----------------------------------------------------------------------------
var _current_zoom: float = 1.0


func _ready() -> void:
	# Buscar objetivo si no fue asignado directamente
	if not target and not target_node_path.is_empty():
		target = get_node_or_null(target_node_path) as Node3D

	if not target:
		# Intentar buscar por grupo "player" o por nombre común
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			target = players[0] as Node3D
		else:
			var candidate := get_parent().find_child("Character", true, false)
			if candidate and candidate is Node3D:
				target = candidate

	# Posicionar inmediatamente la cámara al inicio
	if target:
		global_position = target.global_position + (isometric_offset * _current_zoom)
		look_at(target.global_position, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if not enable_zoom:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.is_pressed():
			_current_zoom = clampf(_current_zoom - (0.1 * zoom_speed), min_zoom_scale, max_zoom_scale)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_pressed():
			_current_zoom = clampf(_current_zoom + (0.1 * zoom_speed), min_zoom_scale, max_zoom_scale)


func _physics_process(delta: float) -> void:
	if not target:
		return

	var target_position := target.global_position + (isometric_offset * _current_zoom)
	global_position = global_position.lerp(target_position, follow_speed * delta)
	
	# Mantener la vista orientada hacia el jugador
	look_at(target.global_position, Vector3.UP)
