-- Simple particle presets (placeholders until custom VFX).
-- count = burst size, rate = looping emit rate. Other keys are ParticleEmitter properties.
local P = require(script.Parent.Palette)

return {
	Impact = { count = 14, Color = ColorSequence.new(P.Stone), Size = NumberSequence.new(1.2, 0), Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(15, 30), SpreadAngle = Vector2.new(180, 180), Drag = 4 },
	BigImpact = { count = 30, Color = ColorSequence.new(P.Sun, P.Coral), Size = NumberSequence.new(2, 0), Lifetime = NumberRange.new(0.3, 0.7), Speed = NumberRange.new(25, 50), SpreadAngle = Vector2.new(180, 180), Drag = 5, LightEmission = 0.5 },
	Trick = { count = 20, Color = ColorSequence.new(P.Sun, P.Grape), Size = NumberSequence.new(0.8, 0), Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(10, 20), SpreadAngle = Vector2.new(180, 180), LightEmission = 1 },
	Boost = { rate = 70, Color = ColorSequence.new(P.Sun, P.Orange), Size = NumberSequence.new(1.4, 0), Lifetime = NumberRange.new(0.15, 0.3), Speed = NumberRange.new(20, 30), SpreadAngle = Vector2.new(12, 12), LightEmission = 1, EmissionDirection = Enum.NormalId.Back },
	Explosion = { count = 60, Color = ColorSequence.new(P.Sun, P.Coral), Size = NumberSequence.new(5, 0), Lifetime = NumberRange.new(0.4, 0.9), Speed = NumberRange.new(40, 90), SpreadAngle = Vector2.new(180, 180), Drag = 3, LightEmission = 1 },
	Confetti = { count = 80, Color = ColorSequence.new(P.Sun, P.Sky), Size = NumberSequence.new(0.6), Lifetime = NumberRange.new(1, 2), Speed = NumberRange.new(30, 50), SpreadAngle = Vector2.new(60, 60), Acceleration = Vector3.new(0, -40, 0), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-200, 200) },
}
