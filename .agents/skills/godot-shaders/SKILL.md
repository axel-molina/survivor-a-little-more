---
name: godot-shaders
description: >-
  Comprehensive guide, cheatsheet, and reference for creating, editing, debugging, and optimizing
  Godot 4 shaders (.gdshader), including Spatial (3D), CanvasItem (2D & UI), Particles, Sky, Fog,
  and Screen-Reading / Post-Processing effects. Use this skill whenever creating or modifying shaders,
  implementing visual effects (toon shading, outlines, dissolve, hit flash, water, foliage wind),
  or porting GLSL / Shadertoy code to Godot.
---

# Godot 4 Shaders Expert Skill

This skill provides complete, production-ready knowledge and best practices for creating, modifying,
and optimizing shaders in Godot 4 using the Godot Shading Language (`.gdshader`).

---

## 1. Quick Overview: Shader Types & Processors

Godot shaders require a `shader_type` declaration at the very top:

| `shader_type` | Use Case | Main Processor Functions |
|---|---|---|
| `spatial` | 3D meshes, characters, environment | `vertex()`, `fragment()`, `light()` |
| `canvas_item` | 2D sprites, CanvasLayers, UI, Control nodes | `vertex()`, `fragment()`, `light()` |
| `particles` | GPU particle simulations & trails | `start()`, `process()` |
| `sky` | Custom 3D skyboxes & atmospheric rendering | `sky()` |
| `fog` | Volumetric fog shaders | `fog()` |

---

## 2. Core Shading Language Rules & Syntax

1. **Variables & Data Types**:
   - `float`, `int`, `uint`, `bool`
   - `vec2`, `vec3`, `vec4` (vectors)
   - `ivec2`, `ivec3`, `ivec4`, `uvec2`, `uvec3`, `uvec4`, `bvec2`, `bvec3`, `bvec4`
   - `mat2`, `mat3`, `mat4` (matrices are **column-major**)
   - `sampler2D`, `sampler2DArray`, `sampler3D`, `samplerCube`

2. **Uniforms & Inspector Hints**:
   ```glsl
   uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
   uniform float roughness : hint_range(0.0, 1.0, 0.01) = 0.5;
   uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
   uniform sampler2D normal_map : hint_normal;
   uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
   uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
   ```

3. **Render Modes**:
   - **Spatial**: `render_mode unshaded`, `cull_disabled`, `cull_front`, `depth_draw_always`, `diffuse_toon`, `specular_toon`, `blend_mix`, `blend_add`.
   - **CanvasItem**: `render_mode unshaded`, `blend_mix`, `blend_add`, `blend_sub`, `blend_mul`.

---

## 3. Reference Guides Index

For deep dives into specific topics, consult the references:

- 📖 **[Language Syntax & Built-in Functions](./references/language_syntax.md)**: Full operator table, math functions, matrix transformations, and preprocessor directives.
- 🎨 **[Spatial (3D) Shaders](./references/spatial_shaders.md)**: Vertex displacement, PBR channels (`ALBEDO`, `METALLIC`, `ROUGHNESS`, `EMISSION`, `NORMAL_MAP`), Toon shading, custom lighting.
- 🖼️ **[CanvasItem (2D & UI) Shaders](./references/canvas_item_shaders.md)**: 2D vertex manipulation, `COLOR`, `UV`, `TEXTURE`, UI effects, transits, healthbars.
- 🔍 **[Screen-Reading & Post-Processing](./references/screen_reading_shaders.md)**: Screen texture, linearizing depth buffer, world-position reconstruction, outlines, blurs, distortions.
- 🔄 **[GLSL & Shadertoy Conversion Guide](./references/glsl_conversion.md)**: Cheat sheet to convert Shadertoy and standard GLSL code to Godot 4 `.gdshader`.

---

## 4. Ready-to-Use Examples Library

Reference implementations located in the `examples/` directory:

1. **[Toon Outline 3D](./examples/toon_outline_3d.gdshader)**: Inverted hull technique with vertex normal expansion in world space (handles scaled meshes).
2. **[Hit Flash / Damage Flash 3D](./examples/hit_flash_damage.gdshader)**: Clean white/red damage flash with emission control.
3. **[Screen Blur Translucent 2D](./examples/screen_blur_translucent.gdshader)**: Real-time UI pause blur with tint and mipmap filtering.
4. **[Dissolve / Burning Edge 3D](./examples/dissolve_burn.gdshader)**: Noise-driven alpha clipping with glowing fiery burn border.
5. **[Stylized Water with Depth Foam 3D](./examples/stylized_water.gdshader)**: Normal wave panning, depth-based shore foam, and refraction.
6. **[Foliage / Grass Wind Sway 3D](./examples/foliage_wind_sway.gdshader)**: Vertex displacement based on world coordinates and UV height gradient.

---

## 5. Best Practices & Troubleshooting Checklist

- ✅ **World-Space vs Model-Space Scaling**: If a 3D mesh has uneven or large scales (e.g. FBX models at scale 100x), expand outlines in world space using `(MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz` or transform normals via `(MODEL_NORMAL_MATRIX * NORMAL)`.
- ✅ **Screen Reading in Godot 4**: In Godot 4, `SCREEN_TEXTURE` is replaced by `uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;` and sampled using `texture(screen_tex, SCREEN_UV)` or `textureLod(screen_tex, SCREEN_UV, lod)`.
- ✅ **Transparent Sorting**: Use `render_mode depth_draw_always;` or alpha scissor `ALPHA_SCISSOR_THRESHOLD = 0.5;` when possible to avoid depth sorting issues with transparent objects.
- ✅ **Mobile / Compatibility Renderer Support**: Avoid branching inside loops; use `filter_linear_mipmap` on sampler uniforms for smooth mipmap level-of-detail sampling.
