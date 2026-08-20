shader_type spatial;
render_mode depth_draw_always, cull_disabled;

## Shader de disolución con borde incandescente (Dissolve & Burn)
## Ideal para desintegración de enemigos abatidos o aparición de objetos.

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable;

uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform float burn_size : hint_range(0.0, 0.2) = 0.05;
uniform vec4 burn_color_outer : source_color = vec4(1.0, 0.2, 0.0, 1.0);
uniform vec4 burn_color_inner : source_color = vec4(1.0, 0.9, 0.2, 1.0);
uniform float emission_strength : hint_range(1.0, 10.0) = 4.0;

void fragment() {
	vec4 base_color = texture(albedo_texture, UV);
	float noise_val = texture(noise_texture, UV).r;
	
	// Si el valor del ruido es inferior a la disolución, descartar el píxel
	if (noise_val < dissolve_amount) {
		discard;
	}
	
	// Calcular el borde ardiente
	float burn_factor = 1.0 - smoothstep(dissolve_amount, dissolve_amount + burn_size, noise_val);
	
	if (burn_factor > 0.0) {
		// Gradiente de color en el fuego
		vec3 fire_color = mix(burn_color_outer.rgb, burn_color_inner.rgb, burn_factor);
		ALBEDO = fire_color;
		EMISSION = fire_color * (burn_factor * emission_strength);
	} else {
		ALBEDO = base_color.rgb;
		EMISSION = vec3(0.0);
	}
	
	ALPHA = base_color.a;
}
