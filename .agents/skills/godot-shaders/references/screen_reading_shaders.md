# Screen-Reading & Post-Processing Shaders (Godot 4)

In Godot 4, screen reading is explicitly declared using uniform hints:
- `hint_screen_texture`
- `hint_depth_texture`
- `hint_normal_roughness_texture`

---

## 1. Declaring Screen Textures

Always declare screen textures as uniforms:

```glsl
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D normal_roughness_texture : hint_normal_roughness_texture, filter_linear_mipmap;
```

> [!IMPORTANT]
> Always add `filter_linear_mipmap` if you plan to use `textureLod(screen_texture, SCREEN_UV, lod_level)` for blur effects.

---

## 2. Screen Blur Effect (CanvasItem)

Used for Pause Menus, glass UI, or frosted panels:

```glsl
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.5;
uniform vec4 tint_color : source_color = vec4(0.0, 0.0, 0.0, 0.45);

void fragment() {
    vec4 blurred_color = textureLod(screen_texture, SCREEN_UV, blur_amount);
    COLOR = mix(blurred_color, vec4(tint_color.rgb, 1.0), tint_color.a);
}
```

---

## 3. Reading and Linearizing the 3D Depth Buffer (Spatial)

The depth buffer stores non-linear depth values in the range `[0.0, 1.0]`. To calculate physical world distances (e.g. water foam, object intersection, fog):

```glsl
shader_type spatial;
render_mode unshaded, depth_draw_never;

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

// Linearizes depth to world space distance from camera in meters
float get_linear_depth(vec2 screen_uv, mat4 inv_proj_matrix) {
    float raw_depth = texture(depth_texture, screen_uv).x;
    vec3 ndc = vec3(screen_uv * 2.0 - 1.0, raw_depth);
    vec4 view_pos = inv_proj_matrix * vec4(ndc, 1.0);
    view_pos.xyz /= view_pos.w;
    return -view_pos.z; // Distance in front of camera
}

void fragment() {
    float scene_depth = get_linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
    float surface_depth = -VERTEX.z; // Current surface depth in view space
    
    float depth_diff = scene_depth - surface_depth;
    
    // Foam threshold
    float foam_line = clamp(1.0 - (depth_diff / 0.3), 0.0, 1.0);
    
    ALBEDO = mix(vec3(0.1, 0.4, 0.8), vec3(1.0, 1.0, 1.0), foam_line);
}
```

---

## 4. Chromatic Aberration / Lens Distortion
```glsl
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 0.05) = 0.008;

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    vec2 dir = SCREEN_UV - center;
    float dist = length(dir);
    
    vec2 offset = dir * (dist * strength);
    
    float r = texture(screen_texture, SCREEN_UV + offset).r;
    float g = texture(screen_texture, SCREEN_UV).g;
    float b = texture(screen_texture, SCREEN_UV - offset).b;
    
    COLOR = vec4(r, g, b, 1.0);
}
```

---

## 5. Fullscreen Pixelation Shader
```glsl
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float pixel_size : hint_range(1.0, 32.0, 1.0) = 4.0;

void fragment() {
    vec2 grid_uv = round(SCREEN_UV / (SCREEN_PIXEL_SIZE * pixel_size)) * (SCREEN_PIXEL_SIZE * pixel_size);
    COLOR = texture(screen_texture, grid_uv);
}
```
