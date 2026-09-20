extends Node
## Global autoload: tracks prototype state and builds the one sound effect
## the game needs at runtime, so the project ships with zero binary assets.

var scare_triggered: bool = false

var stinger_stream: AudioStreamWAV


func _ready() -> void:
	stinger_stream = _build_stinger()


func trigger_scare() -> bool:
	if scare_triggered:
		return false
	scare_triggered = true
	return true


## Procedurally generates a short descending noise-burst "stinger" so the
## project doesn't depend on any imported audio asset.
func _build_stinger() -> AudioStreamWAV:
	var mix_rate := 44100
	var duration := 0.7
	var sample_count := int(mix_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)

	var rng := RandomNumberGenerator.new()
	rng.seed = 1337

	for i in sample_count:
		var t := float(i) / mix_rate
		var progress := float(i) / sample_count

		# Pitch sweeps down fast: 320Hz -> 55Hz.
		var freq: float = lerp(320.0, 55.0, progress)
		var tone: float = sin(TAU * freq * t)

		# Layer in noise so it reads as a growl/hit rather than a pure beep.
		var noise: float = rng.randf_range(-1.0, 1.0)

		# Sharp attack, slow-ish decay envelope.
		var envelope: float = pow(1.0 - progress, 1.6) * clampf(t / 0.01, 0.0, 1.0)

		var sample: float = (tone * 0.6 + noise * 0.4) * envelope
		sample = clampf(sample, -1.0, 1.0)

		var value := int(sample * 32767.0)
		bytes.encode_s16(i * 2, value)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = bytes
	return stream
