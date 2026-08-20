shader_type spatial;
render_mode cull_disabled;

## Shader de viento para vegetación, césped y árboles (Foliage Wind Sway)
## Realiza balanceo en espacio de mundo respetando la base del modelo mediante el canal UV.y.

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform float wind_speed : hint_range(0.1, 5.0) = 1.5;
uniform float wind_strength : hint_range(0.0, 1.0) = 0.2;
uniform vec2 wind_direction = vec2(1.0, 0.5);

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 norm_wind = normalize(wind_direction);
	
	// Oscilación sinusoidal basada en coordenadas mundiales para que los objetos vecinos se muevan en fase
	float wave = sin(TIME * wind_speed + world_pos.x * 0.8 + world_pos.z * 0.8);
	float wave_secondary = cos(TIME * (wind_speed * 1.5) + world_pos.x * 1.2);
	
	float total_sway = (wave + wave_secondary * 0.4) * wind_strength;
	
	// Aplicar mayor desplazamiento a la parte superior (1.0 - UV.y) para no mover las raíces
	float height_factor = clamp(1.0 - UV.y, 0.0, 1.0);
	
	world_pos.x += norm_wind.x * total_sway * height_factor;
	world_pos.z += norm_wind.y * total_sway * height_factor;
	
	VERTEX = (VIEW_MATRIX * vec4(world_pos, 1.0)).xyz;
}

void fragment() {
	vec4 col = texture(albedo_texture, UV);
	ALBEDO = col.rgb;
	ALPHA = col.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
