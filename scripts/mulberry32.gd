class_name Mulberry32
extends RefCounted
## Deterministic PRNG ported bit-for-bit from the mulberry32 algorithm used
## by the reference project (first-vr-game), so seeded scatter layouts
## (forest, pickups) place identically. Godot's 64-bit int holds the full
## unsigned 32-bit range without going negative, so the whole algorithm can
## run in that space and skip JS's signed/unsigned juggling.

var _state: int

func _init(seed: int) -> void:
	_state = seed & 0xFFFFFFFF


## Returns the next float in [0, 1).
func next_f32() -> float:
	_state = (_state + 0x6D2B79F5) & 0xFFFFFFFF
	var t: int = ((_state ^ (_state >> 15)) * (1 | _state)) & 0xFFFFFFFF
	var inner: int = ((t ^ (t >> 7)) * (61 | t)) & 0xFFFFFFFF
	t = ((t + inner) & 0xFFFFFFFF) ^ t
	t = t & 0xFFFFFFFF
	var result_bits: int = (t ^ (t >> 14)) & 0xFFFFFFFF
	return float(result_bits) / 4294967296.0


## Returns a float in [lo, hi).
func range_f32(lo: float, hi: float) -> float:
	return lo + next_f32() * (hi - lo)
