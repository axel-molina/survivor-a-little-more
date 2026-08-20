# Godot 4 Shading Language Syntax & Reference

## 1. Type System

### Scalar & Vector Types
- `void`: Function returns no value
- `bool`: `true` or `false`
- `bvec2`, `bvec3`, `bvec4`: Boolean vectors
- `int`, `uint`: 32-bit signed and unsigned integers (`123`, `123u`)
- `ivec2`, `ivec3`, `ivec4`: Signed integer vectors
- `uvec2`, `uvec3`, `uvec4`: Unsigned integer vectors
- `float`: 32-bit floating point (`1.0`, `1.5f`)
- `vec2`, `vec3`, `vec4`: Floating point vectors

### Matrix Types (Column-Major)
- `mat2`: 2x2 float matrix
- `mat3`: 3x3 float matrix
- `mat4`: 4x4 float matrix

### Sampler Types
- `sampler2D`: 2D texture sampler
- `sampler2DArray`: 2D texture array
- `sampler3D`: 3D volume texture
- `samplerCube`: Cubemap texture
- `isampler2D`, `usampler2D`: Integer samplers

---

## 2. Uniforms & Type Hints

Uniforms expose parameters to the Material Inspector:

```glsl
// Color with color picker
uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Floats with ranges & step
uniform float speed : hint_range(0.0, 10.0, 0.1) = 1.0;
uniform int count : hint_range(1, 100) = 10;

// Textures with filtering and repeat modes
uniform sampler2D main_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap;
uniform sampler2D roughness_texture : hint_roughness_r;

// Special Screen Textures (Godot 4)
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_tex : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D normal_roughness_tex : hint_normal_roughness_texture, filter_linear_mipmap;
```

---

## 3. Global & Instance Uniforms

### Instance Uniforms (Per-Mesh Variations without unique materials)
```glsl
instance uniform vec4 team_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
instance uniform float health_percent : hint_range(0.0, 1.0) = 1.0;
```
Set in GDScript via `geometry_instance_3d.set_instance_shader_parameter("team_color", Color.BLUE)`.

### Global Uniforms (Set project-wide)
```glsl
global uniform vec3 wind_direction;
global uniform float game_time;
```

---

## 4. Built-in Math Functions

- **Trigonometry**: `sin()`, `cos()`, `tan()`, `asin()`, `acos()`, `atan()`, `radians()`, `degrees()`
- **Exponentials**: `pow()`, `exp()`, `log()`, `exp2()`, `log2()`, `sqrt()`, `inversesqrt()`
- **Common**: `abs()`, `sign()`, `floor()`, `ceil()`, `fract()`, `mod()`, `min()`, `max()`, `clamp()`, `mix()`, `step()`, `smoothstep()`
- **Geometric**: `length()`, `distance()`, `dot()`, `cross()`, `normalize()`, `reflect()`, `refract()`, `faceforward()`
- **Vector Relational**: `lessThan()`, `greaterThan()`, `equal()`, `any()`, `all()`, `not()`
- **Texture Sampling**:
  - `texture(sampler2D, vec2 uv)`
  - `textureLod(sampler2D, vec2 uv, float lod)`
  - `textureProj(sampler2D, vec3/vec4 uv)`
  - `texelFetch(sampler2D, ivec2 coord, int lod)`
  - `textureSize(sampler2D, int lod)`

---

## 5. Preprocessor Directives

Godot 4 supports standard shader preprocessor commands and `#include`:

```glsl
#define PI 3.14159265359
#define EPSILON 0.0001

#ifdef USE_NORMAL_MAP
    NORMAL = texture(normal_texture, UV).rgb;
#endif

#include "res://shaders/common_noise.gdshaderinc"
```
