shader_type spatial;
render_mode cull_front, unshaded;

uniform vec4 outline_color : source_color = vec4(1.0, 0.15, 0.15, 1.0);
uniform float outline_width : hint_range(0.0, 0.1, 0.0005) = 0.008;

void vertex() {
	// Calcular la expansión en espacio de mundo para que el grosor sea constante e inmune a la escala del modelo
	vec3 world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz + world_normal * outline_width;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(world_pos, 1.0)).xyz;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a;
}
