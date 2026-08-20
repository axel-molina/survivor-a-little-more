shader_type spatial;
render_mode depth_draw_always, specular_toon;

## Shader de agua estilizada con espuma en orillas mediante búfer de profundidad (Depth Buffer)
## Incluye oleaje doble, distorsión de normales y refracción.

uniform vec4 water_color_shallow : source_color = vec4(0.15, 0.65, 0.85, 0.85);
uniform vec4 water_color_deep : source_color = vec4(0.05, 0.2, 0.45, 0.95);
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float foam_amount : hint_range(0.0, 1.0) = 0.25;
uniform float wave_speed : hint_range(0.01, 1.0) = 0.08;
uniform float wave_scale : hint_range(0.1, 10.0) = 2.0;

uniform sampler2D wave_normal_1 : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D wave_normal_2 : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

float get_linear_depth(vec2 screen_uv, mat4 inv_proj) {
	float raw_depth = texture(depth_texture, screen_uv).x;
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, raw_depth);
	vec4 view_pos = inv_proj * vec4(ndc, 1.0);
	view_pos.xyz /= view_pos.w;
	return -view_pos.z;
}

void fragment() {
	// Desplazamiento de dos capas de normales de olas en direcciones opuestas
	vec2 uv_wave1 = (UV * wave_scale) + vec2(TIME * wave_speed, TIME * (wave_speed * 0.5));
	vec2 uv_wave2 = (UV * wave_scale) - vec2(TIME * (wave_speed * 0.7), TIME * wave_speed);
	
	vec3 normal1 = texture(wave_normal_1, uv_wave1).rgb * 2.0 - 1.0;
	vec3 normal2 = texture(wave_normal_2, uv_wave2).rgb * 2.0 - 1.0;
	NORMAL_MAP = normalize(normal1 + normal2) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.5;
	
	// Cálculo de profundidad lineal para espuma y gradiente de profundidad
	float scene_depth = get_linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	float surface_depth = -VERTEX.z;
	float depth_diff = max(0.0, scene_depth - surface_depth);
	
	// Espuma donde el agua toca el terreno o rocas
	float foam_mask = clamp(1.0 - (depth_diff / foam_amount), 0.0, 1.0);
	
	// Gradiente entre aguas someras y profundas
	float depth_blend = clamp(depth_diff * 0.5, 0.0, 1.0);
	vec4 water_col = mix(water_color_shallow, water_color_deep, depth_blend);
	
	// Composición final con espuma
	ALBEDO = mix(water_col.rgb, foam_color.rgb, foam_mask);
	ALPHA = mix(water_col.a, 1.0, foam_mask);
	ROUGHNESS = 0.05;
	METALLIC = 0.1;
	SPECULAR = 0.8;
}
