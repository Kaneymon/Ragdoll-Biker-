# Street cars (SuperLowPolyCars pack)

The pack as downloaded is in `SuperLowPolyCars/` (FBX models, the 32x16 palette texture and the
.blend). Each car is a body FBX plus separate wheel FBXs that share its origin.

`tools/cars_glb.py` merges every car's body and wheels into one mesh and writes
`SuperLowPolyCars.glb` (45 variants: Sedan, Coupe, Sport, Wagon, Pickup, Truck, Van in colours,
plus Police and Ambulance; tractors left out). Faces are flat shaded and their UVs are snapped to
the middle of their palette colour, so there is no colour bleeding.

- Model asset (the .glb): rbxassetid://83500622778156
- Palette texture (MeshPart.TextureID): rbxassetid://119449447630634

In Studio each variant is `ServerStorage.Assets.Cars.<Name>`: a Model with one MeshPart `Body`,
scaled 4x from the metre-sized import (a Sedan is about 7 x 5 x 15 studs), turned 180 degrees so
the front faces -Z, and sunk 0.1 studs so the tyres don't z-fight with the road. The model's
WorldPivot is the middle of its base (no PrimaryPart, so pivots still work while streamed out).

`Props.car` (src/server/World/Props.luau) clones a random variant for the `cars` prop in
Config/Maps. Cars are hazards (Config/Hazards "Car"): not solid, and they blow up when you get
within their `HazardRadius` attribute, which is set from the car's length so trucks count end to end.

The old `ToyCar` (assets/models/ToyCar.*) is no longer used.
