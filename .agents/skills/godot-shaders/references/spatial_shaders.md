# Spatial (3D) Shaders Reference

Spatial shaders (`shader_type spatial;`) are used for rendering 3D objects, characters, environments, and particle meshes.

---

## 1. Render Modes

Common render modes specified at the top of the shader:

```glsl
render_mode cull_disabled;      // Render both front and back faces (foliage, double-sided)
render_mode cull_front;         // Render only back faces (inverted hull outlines)
render_mode unshaded;           // Bypass lighting calculation (flat / UI / toon)
render_mode depth_draw_always;  // Always write to depth buffer (useful for alpha sorting)
render_mode diffuse_toon, specular_toon; // Toon/cel shading look
render_mode blend_add;          // Additive blending for holograms, lasers, shields
render_mode wireframe;          // Debug wireframe rendering
```

---

## 2. The `vertex()` Processor

Runs once per vertex of the 3D geometry. Used for animations, wind sways, billboarding, and vertex displacement.

### Input Built-ins:
- `VERTEX`: `inout vec3` (Vertex position in view space)
- `NORMAL`: `inout vec3` (Normal vector in view space)
- `TANGENT`, `BINORMAL`: `inout vec3` (Tangent and bitangent vectors)
- `UV`, `UV2`: `inout vec2` (Texture coordinates)
- `COLOR`: `inout vec4` (Vertex color)
- `MODEL_MATRIX`: `mat4` (Model-to-World transform)
- `VIEW_MATRIX`: `mat4` (World-to-View transform)
- `MODELVIEW_MATRIX`: `mat4` (Model-to-View transform)
- `PROJECTION_MATRIX`: `mat4` (View-to-Clip projection)
- `INV_VIEW_MATRIX`: `mat4` (View-to-World transform)
- `TIME`: `float` (Elapsed game time in seconds)

### Example: World-Position Wind Sway for Foliage
```glsl
void vertex() {
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float wind = sin(TIME * 2.0 + world_pos.x * 1.5 + world_pos.z * 1.5);
    // Displace vertex top only (based on UV.y)
    VERTEX.x += wind * (1.0 - UV.y) * 0.15;
}
```

---

## 3. The `fragment()` Processor

Runs for every rendered pixel/fragment. Used for setting PBR material channels, colors, and textures.

### Output Built-ins:
- `ALBEDO`: `vec3` (Base diffuse color, range 0.0 - 1.0)
- `ALPHA`: `float` (Transparency / Opacity, range 0.0 - 1.0)
- `ALPHA_SCISSOR_THRESHOLD`: `float` (Cutout threshold, e.g. `0.5` for crisp alpha cutouts)
- `METALLIC`: `float` (Dielectric = 0.0, Metal = 1.0)
- `ROUGHNESS`: `float` (Smooth/Mirror = 0.0, Rough = 1.0)
- `SPECULAR`: `float` (Specular reflection intensity, default 0.5)
- `EMISSION`: `vec3` (Emissive light color that glows in bloom/HDR)
- `NORMAL`: `vec3` (Surface normal in view space)
- `NORMAL_MAP`: `vec3` (Tangent space normal map, values 0.0 - 1.0)
- `NORMAL_MAP_DEPTH`: `float` (Strength of normal map)
- `RIM`: `float` (Rim lighting intensity)
- `RIM_TINT`: `float` (Rim lighting tint)
- `CLEARCOAT`: `float` (Secondary specular clearcoat layer)
- `ANISOTROPY`: `float` (Brushed metal anisotropy)
- `AO`: `float` (Ambient occlusion factor)

### Example: Hit Damage White/Red Flash
```glsl
uniform vec4 hit_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float hit_flash_intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    ALBEDO = mix(tex.rgb, hit_color.rgb, hit_flash_intensity);
    EMISSION = hit_color.rgb * hit_flash_intensity * 2.0;
}
```

---

## 4. The `light()` Processor

Runs for each light affecting the fragment (Directional, Omni, Spot).

### Built-ins:
- `LIGHT`: `vec3` (Light direction in view space)
- `LIGHT_COLOR`: `vec3` (Color & intensity of the light)
- `ATTENUATION`: `float` (Shadow and distance attenuation factor)
- `DIFFUSE_LIGHT`: `inout vec3` (Accumulated diffuse lighting)
- `SPECULAR_LIGHT`: `inout vec3` (Accumulated specular lighting)

### Example: Custom 2-Step Cel / Toon Light
```glsl
void light() {
    float n_dot_l = dot(NORMAL, LIGHT);
    float light_band = smoothstep(0.0, 0.05, n_dot_l) * 0.7 + 0.3;
    DIFFUSE_LIGHT += LIGHT_COLOR * ALBEDO * light_band * ATTENUATION;
}
```
