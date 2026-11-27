# Lobby props

Built by `tools/lobby_props_blender.py` (shared pipeline in `tools/blender_props_lib.py`), kept in
Studio as `ServerStorage.Assets.Lobby.<Prop>` (one MeshPart named `Mesh` + SurfaceAppearance).
Mesh model asset: rbxassetid://80335186748838 (LobbyProps.fbx).

| Prop       | ColorMap                     | NormalMap                     |
|------------|------------------------------|-------------------------------|
| ShopStall  | rbxassetid://84155899493080  | rbxassetid://103628769692357  |
| BoardFrame | rbxassetid://129387143090082 | rbxassetid://135190308151494  |
| Beanbag    | rbxassetid://107753182437622 | rbxassetid://94297978739451   |

`src/server/World/LobbyBuilder.luau` places them from `src/shared/Config/Lobby.luau`. Shop names,
board titles and leaderboard rows are SurfaceGui text drawn on in Roblox.
