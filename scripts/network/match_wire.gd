extends RefCounted
## Only explicitly listed match state crosses the wire; RNG stays on the host.
const FIELDS := ["lives", "teams", "offers", "actions_left", "comeback_used", "passed", "turn_player", "priority_player", "round_number", "phase", "initial_order", "initial_pick_index", "next_token", "last_result", "match_winner"]
static func capture(model: RefCounted) -> Dictionary:
	var state: Dictionary = {}
	for field in FIELDS:
		var value: Variant = model.get(field)
		state[field] = value.duplicate(true) if value is Array or value is Dictionary else value
	return state

static func apply(model: RefCounted, state: Dictionary) -> void:
	for field in FIELDS:
		if not state.has(field): continue
		var old: Variant = model.get(field)
		if old is Array: old.assign(state[field].duplicate(true))
		else: model.set(field, state[field])
