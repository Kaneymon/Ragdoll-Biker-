# Skate Park props

Built by `tools/skate_props_blender.py` (run inside Blender; shared helpers in
`tools/blender_props_lib.py`), chain-link and graffiti painted by `tools/skate_textures.py`.
Each prop is one mesh with baked `<Prop>_Color.png` (RGBA for the chain-link) and `<Prop>_Normal.png`.

In Roblox the meshes live in ServerStorage.Assets.Skate with a SurfaceAppearance per prop:

| Prop | ColorMap | NormalMap |
|---|---|---|
| QuarterPipe | 126821818462309 | 131945766940942 |
| SkateLaunchRamp | 118193505297563 | 78804614079260 |
| JumpBox | 140290198854145 | 109203678607671 |
| GrindBox | 94287117281861 | 128979099759046 |
| GrindRail | 81313691296056 | 83419450963021 |
| HipBump | 107574065045586 | 117405620373766 |
| SkateBench | 86441684199059 | 84574445062431 |
| ChainLinkFence (alpha) | 115062066853095 | 101931494921967 |

Graffiti decal ids are in `src/shared/Config/Decals.luau`.
