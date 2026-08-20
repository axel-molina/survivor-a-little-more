shader_type spatial;

## Shader de impacto/daño (Hit Flash) para personajes y enemigos
## Mezcla el albedo con un color de impacto y emite luz brillante para feedback visual.

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec4 hit_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float hit_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 base_tex = texture(albedo_texture, UV);
	
	// Mezcla entre la textura original y el color de impacto
	ALBEDO = mix(base_tex.rgb, hit_color.rgb, hit_intensity);
	
	// Destello de emisión que resalta con bloom/Glow
	EMISSION = hit_color.rgb * (hit_intensity * 2.5);
	
	METALLIC = metallic;
	ROUGHNESS = roughness;
	ALPHA = base_tex.a;
}
