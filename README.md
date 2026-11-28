# Ragdoll Biker 💀🦴

Roblox game: ride down a mega ramp, launch off the kicker, do tricks, bail, break bones, cash the insurance payout, upgrade, repeat.

## Layout (Rojo)

```
src/shared  -> ReplicatedStorage.Shared
  Config/    all game data: prices, upgrades, boosters, exploders, injuries, tricks, maps, text, sounds, VFX, palette
  Logic/     pure shared rules: Progression (prices/stats), InjuryModel (damage -> money), TrickScore, Ragdoll, RiderPose, Joints
  Services/  reusable services: Localize (text keys), Sfx (sound hooks), Vfx (particles)
  Util/      Signal, Format
  Net.luau   remotes listed in Config/Remotes
src/server  -> ServerScriptService.Server
  Services/  DataService, ShopService, MonetizationService (Robux stub), WorldService, BikeService, RunTracker
  World/     MapBuilder, Props, BikeBuilder, Build helpers
src/client  -> StarterPlayer.StarterPlayerScripts.Client
  State.luau         client event hub (controllers fire, UI/Feedback listen)
  Controllers/       Input, BikeController, TrickController, RagdollController, DamageDetector, GearController, CameraController, Session
  Feedback/          the only place gameplay events become sounds, particles and camera shake
  UI/                UiKit + Window + Card building blocks, Hud, PayoutSheet, Upgrades/Store/Settings windows, OfferPopup
assets/models       Blender BMX (BMX.blend, BMX.fbx, preview) for when the mesh is imported
tools/checksums.py  prints a checksum per script, used to check Studio matches the repo
```

## Rules of the codebase

- Numbers and text live in `Config/`. Logic never hardcodes prices, stats or strings.
- UI text is always a key from `Config/Text.luau` (Localize builds a LocalizationTable for auto-translation).
- Gameplay code fires `State` events. Sounds/VFX/shake are only in `Feedback/Feedback.luau`.
- Sounds are hooks: put `rbxassetid://` ids into `Config/Sounds.luau`; empty ids play nothing.
- The server re-scores tricks and impacts from reports with sanity caps; money only changes on the server.

## Syncing to Studio

Install Rojo and run `rojo serve`, then connect from the Rojo Studio plugin. The Hill & Park map is baked
into the place (`Workspace.World.hill_park`); if it is deleted, `WorldService` rebuilds it from `Config/Maps.luau`.

Place settings the code relies on: `Workspace.FallenPartsDestroyHeight = -2000`, mouse lock off,
`Workspace.StreamingEnabled = true` (min radius 512, target 2048, MinimumRadiusPause). Without streaming
every client downloads all six maps and the Mountain's terrain before a playtest can start.
To keep progress in Studio tests, turn on Game Settings > Security > Enable Studio Access to API Services.

## Controls

| Action | PC | Gamepad |
|---|---|---|
| Pedal / brake / steer | W / S / A D | Left stick |
| Flip (air) | W front flip, S backflip | Left stick |
| Side flip (air) | A / D | Left stick |
| Hop (ground) / Bail (air) | Space | A |
| Boost | Left Shift | R2 |
| Explode | X | Y |
| Tailwhip / Barspin | Q / E | L1 / R1 |
| Superman / Lazy Boy | R / F | X / B |

Phones get on-screen buttons for every action.
