shader_type canvas_item;

## Shader de chispas y brasas de fogata (Campfire Embers)
## Genera chispas procedurales flotantes que ascienden con movimiento orgánico, brillo y parpadeo.

uniform float ember_density : hint_range(5.0, 30.0) = 14.0;
uniform float speed : hint_range(0.1, 2.0) = 0.45;
uniform float sway_intensity : hint_range(0.0, 2.0) = 0.7;
uniform float ember_size : hint_range(0.01, 0.2) = 0.06;
uniform vec4 ember_color_core : source_color = vec4(1.0, 0.95, 0.6, 1.0);
uniform vec4 ember_color_glow : source_color = vec4(1.0, 0.4, 0.05, 0.9);
uniform float glow_strength : hint_range(0.5, 3.0) = 1.5;

// Hash pseudo-aleatorio para distribución determinista en celdas
vec2 hash22(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;
	vec4 final_color = vec4(0.0);
	
	// Tres capas con efecto de profundidad (fondo, plano medio y primer plano)
	for (int l = 0; l < 3; l++) {
		float layer_scale = float(l) * 0.6 + 1.0;
		float layer_speed = speed * (0.7 + float(l) * 0.35);
		vec2 layer_uv = vec2(uv.x, uv.y + TIME * layer_speed * 0.3) * (ember_density * layer_scale);
		
		vec2 cell_id = floor(layer_uv);
		vec2 cell_fract = fract(layer_uv);
		
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec2 neighbor = vec2(float(x), float(y));
				vec2 current_cell = cell_id + neighbor;
				
				vec2 rand = hash22(current_cell + float(l) * 31.17);
				
				// Movimiento con oscilación térmica y balanceo
				float seed = rand.x * 6.2831;
				float time_offset = TIME * (layer_speed * 2.0) + rand.y * 10.0;
				
				vec2 ember_offset = neighbor + rand + vec2(
					sin(time_offset + seed) * (0.35 * sway_intensity),
					cos(time_offset * 0.7 + seed) * 0.2
				) - cell_fract;
				
				// Desvanecimiento suave en la parte superior e inferior de la pantalla
				float screen_y = uv.y;
				float life_fade = smoothstep(1.0, 0.85, screen_y) * smoothstep(0.02, 0.3, screen_y);
				
				// Parpadeo de calor
				float flicker = 0.65 + 0.35 * sin(TIME * 8.0 + rand.x * 50.0);
				
				float dist = length(ember_offset);
				float radius = ember_size * (0.4 + rand.y * 0.8) / layer_scale;
				
				if (dist < radius * 3.5 && life_fade > 0.01) {
					float core = smoothstep(radius * 0.3, 0.0, dist);
					float glow = exp(-dist / (radius * 1.2));
					
					vec3 col = mix(ember_color_glow.rgb, ember_color_core.rgb, core);
					float alpha = (core + glow * 0.6 * glow_strength) * life_fade * flicker;
					
					final_color.rgb += col * alpha;
					final_color.a += alpha * 0.7;
				}
			}
		}
	}
	
	final_color.a = clamp(final_color.a, 0.0, 1.0);
	COLOR = final_color;
}
