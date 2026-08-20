# Porting GLSL & Shadertoy to Godot 4 Shaders

## 1. Quick Translation Table

| Shadertoy / GLSL | Godot 4 CanvasItem (`.gdshader`) | Godot 4 Spatial (`.gdshader`) | Notes |
|---|---|---|---|
| `iResolution.xy` | `1.0 / SCREEN_PIXEL_SIZE` | `1.0 / VIEWPORT_SIZE` | Screen resolution in pixels |
| `iTime` / `time` | `TIME` | `TIME` | Elapsed time in seconds |
| `fragCoord` | `FRAGCOORD.xy` | `FRAGCOORD.xy` | Pixel coordinates |
| `fragColor` | `COLOR` | `ALBEDO`, `ALPHA` | Output color |
| `iMouse.xy` | Pass via `uniform vec2 mouse` | Pass via `uniform vec2 mouse` | Must be passed from GDScript |
| `texture2D(tex, uv)` | `texture(tex, uv)` | `texture(tex, uv)` | Standard sampling |
| `gl_FragDepth` | `DEPTH` | `DEPTH` | Fragment depth write |
| `mat4` multiplication | `mat4 * vec4` | `mat4 * vec4` | Column-major in Godot |
| `atan(y, x)` | `atan(y, x)` | `atan(y, x)` | Two-argument form supported |
| `mod(x, y)` | `mod(x, y)` | `mod(x, y)` | Supports float & vectors |

---

## 2. Converting a Shadertoy `mainImage` Function

### Original Shadertoy Pattern:
```glsl
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec3 col = 0.5 + 0.5 * cos(iTime + uv.xyx + vec3(0, 2, 4));
    fragColor = vec4(col, 1.0);
}
```

### Converted Godot 4 Shader (`canvas_item`):
```glsl
shader_type canvas_item;

void fragment() {
    vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 uv = (FRAGCOORD.xy - 0.5 * res) / res.y;
    vec3 col = 0.5 + 0.5 * cos(TIME + uv.xyx + vec3(0.0, 2.0, 4.0));
    COLOR = vec4(col, 1.0);
}
```

---

## 3. Key Godot 4 GLSL Differences & Pitfalls

1. **Precision Qualifiers**:
   - `precision highp float;` is **not required** and will trigger syntax errors if placed at the top. Godot assigns precision automatically.
2. **Implicit Float Conversion**:
   - In GLSL / Godot shaders, `float x = 1;` is invalid; always write `float x = 1.0;`.
   - `vec3(0, 2, 4)` must be written `vec3(0.0, 2.0, 4.0)`.
3. **Array Initialization**:
   - In Godot 4: `float vals[3] = float[3](1.0, 2.0, 3.0);`.
4. **Varyings**:
   - To pass data from `vertex()` to `fragment()`, declare a `varying`:
   ```glsl
   varying vec3 v_world_pos;
   
   void vertex() {
       v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
   }
   
   void fragment() {
       float dist = length(v_world_pos);
   }
   ```
