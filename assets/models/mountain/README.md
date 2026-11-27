# Mountain props

Built by `tools/mountain_props_blender.py` (shared pipeline in `tools/blender_props_lib.py`),
kept in Studio as `ServerStorage.Assets.Mountain.<Prop>` (one MeshPart named `Mesh` + SurfaceAppearance).
The Mountain's pine trees reuse the park's `FirTree` (`MeshProps.pines`).

| Prop    | Mesh (MountainProps.fbx) | ColorMap                       | NormalMap                       |
|---------|--------------------------|--------------------------------|---------------------------------|
| Boulder | rbxassetid://123882219964640 | rbxassetid://72954483389456 | rbxassetid://85749408838124 |

The ground itself is Roblox terrain, laid by `src/server/World/TerrainBuilder.luau` from
`Config/Maps` `terrain` (Studio builds it in row batches with `TerrainBuilder.build`, then
`MapBuilder.build(def, parent, { skipTerrain = true })`).
