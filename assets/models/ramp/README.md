# Mega ramp look

Built by `tools/ramp_props_blender.py` (shared pipeline in `tools/blender_props_lib.py`).

| Asset | What | Ids |
|-------|------|-----|
| Chipboard tile | `MaterialService.Chipboard` MaterialVariant (BaseMaterial Wood, StudsPerTile 16) | ColorMap rbxassetid://113759897317975, NormalMap rbxassetid://102142087756889 |
| RampBarrier | `ServerStorage.Assets.Ramp.RampBarrier` (16 stud metal barrier section) | Mesh rbxassetid://136949180967727, ColorMap rbxassetid://92380474024424, NormalMap rbxassetid://137019000933803 |

`src/shared/Config/MegaRamp.luau` says how MapBuilder uses them.
