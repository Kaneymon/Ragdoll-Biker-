# Park props

Built by `tools/park_props_blender.py` (run inside Blender) from the painted source textures in
`src/` (`tools/park_textures.py`). Each prop is one mesh with its own baked textures:
`<Prop>_Color.png` (albedo + AO + edge highlights; RGBA for leaf cards) and `<Prop>_Normal.png`.

In Roblox the meshes live in ServerStorage.Assets.Park (model asset 94644543724985, scaled 0.01)
with a SurfaceAppearance per prop:

| Prop | ColorMap | NormalMap |
|---|---|---|
| OakTree (alpha) | 122497285703154 | 85183805081320 |
| FirTree | 70717657520842 | 78548701443099 |
| Bush (alpha) | 132690563179731 | 138766145111316 |
| FlowerPatch | 101240539131853 | 112738389441072 |
| Bench | 81651730119674 | 86763584730371 |
| PicnicTable | 82728396072672 | 81194797099538 |
| Lamp | 91368396267364 | 77733248430856 |
| SwingSet | 76617787851363 | 100420713700106 |
| JungleGym | 95193955772378 | 100615264391710 |
| GrassClump (alpha, tools/grass_props_blender.py) | 86079289662855 | 70735853059158 |
