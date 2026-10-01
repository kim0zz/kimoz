extends RefCounted
## Symmetric swept-circle movement and local avoidance of allied bodies.

const GRID: float = 1.0 / 512.0

static func _world(centered: Vector2, arena: Vector2) -> Vector2:
	# Snap before adding the origin: reflected coordinates retain identical precision.
	return Vector2(roundf(centered.x / GRID) * GRID, roundf(centered.y / GRID) * GRID) + arena * 0.5

static func translated(pos: Vector2, delta: Vector2, arena: Vector2) -> Vector2:
	return _world((pos - arena * 0.5) + delta, arena)

static func toward(pos: Vector2, target: Vector2, distance: float, arena: Vector2) -> Vector2:
	return _world((pos - arena * 0.5).move_toward(target - arena * 0.5, distance), arena)

static func interpolated(a: Vector2, b: Vector2, weight: float, arena: Vector2) -> Vector2:
	return _world((a - arena * 0.5).lerp(b - arena * 0.5, weight), arena)

static func clamp_position(pos: Vector2, radius: float, arena: Vector2) -> Vector2:
	var half: Vector2 = arena * 0.5
	var centered: Vector2 = pos - half
	# Inward lattice limits preserve radius constraints even for non-grid radii.
	var limit := Vector2(floorf((half.x - radius) / GRID) * GRID, floorf((half.y - radius) / GRID) * GRID)
	centered = Vector2(clampf(centered.x, -limit.x, limit.x), clampf(centered.y, -limit.y, limit.y))
	return _world(centered, arena)

static func steer(unit: Dictionary, heading: Vector2, units: Array, arena: Vector2) -> Vector2:
	# A short local detour avoids queues behind allies without assigning target slots.
	# A wall alone must not trigger orbiting: ranged units pinned there stand and fire.
	if bool(unit.get("phase_active", false)): return heading
	if _clear_lane(unit, heading, units, arena, false): return heading
	var facing: float = 1.0 if unit.team == 0 else -1.0
	var side: float = float(unit.get("steer_side", -1.0 if int(unit.slot) % 2 == 0 else 1.0))
	for angle in [0.45, 0.9, 1.35, PI * 0.5]:
		for turn in [side, -side]:
			var candidate: Vector2 = heading.rotated(angle * turn * facing)
			if _clear_lane(unit, candidate, units, arena):
				unit["steer_side"] = turn
				return candidate
	return Vector2.ZERO

static func _clear_lane(unit: Dictionary, direction: Vector2, units: Array, arena: Vector2, check_bounds: bool = true) -> bool:
	var lookahead: float = 20.0
	var end: Vector2 = translated(unit.pos, direction * lookahead, arena)
	if check_bounds and clamp_position(end, unit.definition.radius, arena).distance_to(end) > 1.0:
		return false
	for other: Dictionary in units:
		if not other.alive or other.uid == unit.uid or other.team != unit.team or (bool(other.get("motion_dive", false)) or bool(other.get("phase_active", false))):
			continue
		var delta: Vector2 = Vector2(other.pos) - Vector2(unit.pos)
		var forward: float = delta.dot(direction)
		if forward <= 0.0: continue
		var closest: Vector2 = direction * clampf(forward, 0.0, lookahead)
		if (delta - closest).length() < unit.definition.radius + other.definition.radius + 2.0:
			return false
	return true

static func correct_landings(units: Array, landing_ids: Array, arena: Vector2) -> void:
	# Jacobi projection: all pair constraints read one snapshot and commit together.
	# Only landing units can move; ordinary movement and airborne dives are untouched.
	if landing_ids.is_empty():
		return
	for iteration in range(96):
		var corrections: Array[Vector2] = []
		var contacts: Array[int] = []
		for u: Dictionary in units:
			corrections.append(Vector2.ZERO)
			contacts.append(0)
		var overlap_found: bool = false
		for i in range(units.size()):
			var a: Dictionary = units[i]
			if not a.alive:
				continue
			var a_lands: bool = i in landing_ids
			if (bool(a.get("motion_dive", false)) or bool(a.get("phase_active", false))) and not a_lands:
				continue
			for j in range(i + 1, units.size()):
				var b: Dictionary = units[j]
				var b_lands: bool = j in landing_ids
				if not b.alive or not (a_lands or b_lands):
					continue
				if (bool(b.get("motion_dive", false)) or bool(b.get("phase_active", false))) and not b_lands:
					continue
				var delta: Vector2 = Vector2(a.pos) - Vector2(b.pos)
				var distance: float = delta.length()
				var required: float = a.definition.radius + b.definition.radius + GRID * 2.0
				if distance >= required - 0.001:
					continue
				overlap_found = true
				# Team-relative fallback mirrors exactly when centers coincide.
				var normal: Vector2 = delta / distance if distance > 0.00001 else (Vector2.LEFT if a.team == 0 else Vector2.RIGHT)
				if distance <= 0.00001 and a_lands != b_lands:
					var lander: Dictionary = a if a_lands else b
					var direction: Vector2 = normal if a_lands else -normal
					var probe: Vector2 = clamp_position(translated(lander.pos, direction * required, arena), lander.definition.radius, arena)
					if probe.distance_to(lander.pos) < required * 0.5:
						direction = Vector2.DOWN if lander.pos.y < arena.y * 0.5 else Vector2.UP
						normal = direction if a_lands else -direction
				var correction: Vector2 = normal * (required - distance + 0.002)
				if a_lands and b_lands:
					corrections[i] += correction * 0.5
					corrections[j] -= correction * 0.5
					contacts[i] += 1
					contacts[j] += 1
				elif a_lands:
					corrections[i] += correction
					contacts[i] += 1
				else:
					corrections[j] -= correction
					contacts[j] += 1
		for uid: int in landing_ids:
			var u: Dictionary = units[uid]
			if u.alive:
				# Averaging prevents multi-contact sums from oscillating across a crowd.
				var correction: Vector2 = corrections[uid] / maxi(1, contacts[uid])
				u.pos = clamp_position(translated(u.pos, correction, arena), u.definition.radius, arena)
		if not overlap_found:
			break

static func apply(units: Array, desired: Array[Vector2], arena: Vector2, dt: float) -> void:
	var displacement: Array[Vector2] = []
	var fractions: Array[float] = []
	for u: Dictionary in units:
		displacement.append(clamp_position(desired[u.uid], u.definition.radius, arena) - Vector2(u.pos))
		fractions.append(1.0)
	# Re-sweep after truncation: stopping B against C must also constrain A following B.
	# Each pass reads the previous fractions and commits constraints together.
	for iteration in range(units.size() * 2):
		var next_fractions: Array[float] = fractions.duplicate()
		for i in range(units.size()):
			var a: Dictionary = units[i]
			if not a.alive:
				continue
			for j in range(i + 1, units.size()):
				var b: Dictionary = units[j]
				if not b.alive:
					continue
				if (bool(a.get("motion_dive", false)) or bool(a.get("phase_active", false))) or (bool(b.get("motion_dive", false)) or bool(b.get("phase_active", false))):
					continue
				var relative: Vector2 = Vector2(a.pos) - Vector2(b.pos)
				var delta: Vector2 = displacement[i] * fractions[i] - displacement[j] * fractions[j]
				var radius: float = a.definition.radius + b.definition.radius + GRID * 2.0
				var c: float = relative.length_squared() - radius * radius
				var dot: float = relative.dot(delta)
				if dot >= 0.0 or delta.length_squared() < 0.0000001:
					continue
				var fraction: float = 1.0
				if c <= 0.01:
					fraction = 0.0
				else:
					var discriminant: float = dot * dot - delta.length_squared() * c
					if discriminant >= 0.0:
						fraction = clampf((-dot - sqrt(discriminant)) / delta.length_squared(), 0.0, 1.0)
				next_fractions[i] = minf(next_fractions[i], fractions[i] * fraction)
				next_fractions[j] = minf(next_fractions[j], fractions[j] * fraction)
		if fractions == next_fractions:
			break
		fractions = next_fractions
	for u: Dictionary in units:
		var move: Vector2 = displacement[u.uid] * fractions[u.uid] if u.alive else Vector2.ZERO
		var previous: Vector2 = u.pos
		u.pos = translated(previous, move, arena)
		u.velocity = (Vector2(u.pos) - previous) / dt
