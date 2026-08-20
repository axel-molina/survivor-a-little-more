shader_type spatial;
render_mode cull_front, unshaded;

## Shader de contorno 3D mediante casco invertido (Inverted Hull)
## Funciona correctamente con mallas escaladas (incluyendo modelos FBX a escala 100x).

uniform vec4 outline_color : source_color = vec4(1.0, 0.15, 0.15, 1.0);
uniform float outline_width : hint_range(0.0, 0.1) = 0.02;

void vertex() {
	// Transformar posición y normal a espacio de mundo para evitar distorsiones por escala de nodos padres
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 world_normal = normalize((MODEL_NORMAL_MATRIX * NORMAL).xyz);
	
	// Expandir el vértice hacia afuera a lo largo de la normal en espacio de mundo
	world_pos += world_normal * outline_width;
	
	// Retornar a espacio de vista del shader
	VERTEX = (VIEW_MATRIX * vec4(world_pos, 1.0)).xyz;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a;
}
