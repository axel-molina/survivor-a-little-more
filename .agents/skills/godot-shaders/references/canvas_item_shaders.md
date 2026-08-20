# CanvasItem (2D & UI) Shaders Reference

CanvasItem shaders (`shader_type canvas_item;`) are used for 2D sprites, tiles, UI `Control` nodes, `TextureRect`, `ColorRect`, and 2D post-processing effects.

---

## 1. Render Modes

```glsl
render_mode blend_mix;       // Standard alpha blending (default)
render_mode blend_add;       // Additive blending (lasers, glow, fire, magic)
render_mode blend_sub;       // Subtractive blending (shadows, negative burn)
render_mode blend_mul;       // Multiplicative blending (vignette, tint)
render_mode blend_premul_alpha; // Pre-multiplied alpha
render_mode unshaded;        // Ignores 2D CanvasItem lights (PointLight2D, DirectionalLight2D)
render_mode light_only;      // Render only in areas touched by 2D light
```

---

## 2. The `vertex()` Processor (2D)

Runs once per 2D vertex.

### Built-in Variables:
- `VERTEX`: `inout vec2` (2D vertex coordinate in canvas/local space)
- `UV`: `inout vec2` (Normalized texture coordinate, `0.0` to `1.0`)
- `COLOR`: `inout vec4` (Node modulate/self_modulate or vertex color)
- `TEXTURE_PIXEL_SIZE`: `vec2` (1.0 / texture width and height)
- `TIME`: `float` (Elapsed game time)

### Example: 2D Sprite Wobble / Jelly Animation
```glsl
uniform float wobble_speed = 5.0;
uniform float wobble_amount = 4.0;

void vertex() {
    VERTEX.x += sin(TIME * wobble_speed + VERTEX.y * 0.1) * wobble_amount;
}
```

---

## 3. The `fragment()` Processor (2D)

Runs for every 2D pixel of the item.

### Built-in Variables:
- `COLOR`: `inout vec4` (Final output RGBA color of the pixel)
- `UV`: `vec2` (Texture coordinate)
- `TEXTURE`: `sampler2D` (The texture assigned to the Sprite2D or Control node)
- `TEXTURE_PIXEL_SIZE`: `vec2` (Size of one pixel in UV space, `1.0 / size`)
- `SCREEN_UV`: `vec2` (Normalized screen coordinate, `0.0` to `1.0`)
- `SCREEN_PIXEL_SIZE`: `vec2` (Size of one screen pixel in UV space)
- `POINT_COORD`: `vec2` (Point coordinate for point rendering)
- `AT_LIGHT_PASS`: `bool` (True during a 2D light pass)

### Example: 2D Sprite Outline / Stroke
```glsl
shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 1.0;

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
    float alpha = texture(TEXTURE, UV).a;
    
    // Sample 4 cardinal neighbors
    float max_alpha = max(max(texture(TEXTURE, UV + vec2(size.x, 0.0)).a,
                              texture(TEXTURE, UV - vec2(size.x, 0.0)).a),
                          max(texture(TEXTURE, UV + vec2(0.0, size.y)).a,
                              texture(TEXTURE, UV - vec2(0.0, size.y)).a));
    
    vec4 base_color = texture(TEXTURE, UV) * COLOR;
    
    if (base_color.a < 0.1 && max_alpha > 0.1) {
        COLOR = outline_color;
    } else {
        COLOR = base_color;
    }
}
```

---

## 4. UI Healthbar / Fill Shader
```glsl
shader_type canvas_item;

uniform float fill_amount : hint_range(0.0, 1.0) = 0.75;
uniform vec4 fill_color : source_color = vec4(0.2, 0.8, 0.3, 1.0);
uniform vec4 empty_color : source_color = vec4(0.2, 0.2, 0.2, 0.8);
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float border_width : hint_range(0.0, 0.1) = 0.02;

void fragment() {
    vec2 uv = UV;
    
    // Border check
    bool is_border = uv.x < border_width || uv.x > (1.0 - border_width) ||
                     uv.y < border_width || uv.y > (1.0 - border_width);
    
    if (is_border) {
        COLOR = border_color;
    } else if (uv.x < fill_amount) {
        COLOR = fill_color;
    } else {
        COLOR = empty_color;
    }
}
```
