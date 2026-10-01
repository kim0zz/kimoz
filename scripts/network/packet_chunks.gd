class_name ZooPacketChunks
extends RefCounted

const CHUNK_BYTES := 700
const MAX_BYTES := 131072
const MAX_PARTS := 188
var data := PackedByteArray()
var expected_index := 0
var expected_count := 0
var expected_kind := -1
var raw_size := 0

func clear() -> void:
	data.clear()
	expected_index = 0
	expected_count = 0
	expected_kind = -1
	raw_size = 0

func accept(kind: int, index: int, count: int, size: int, part: PackedByteArray) -> Dictionary:
	if kind < 0 or kind > 3 or size < 1 or size > MAX_BYTES or count < 1 or count > MAX_PARTS or index < 0 or index >= count or part.is_empty() or part.size() > CHUNK_BYTES:
		clear()
		return {"error": true}
	if index == 0:
		if expected_index != 0:
			clear()
			return {"error": true}
		expected_count = count
		expected_kind = kind
		raw_size = size
	if index != expected_index or kind != expected_kind or count != expected_count or size != raw_size or data.size() + part.size() > MAX_BYTES:
		clear()
		return {"error": true}
	data.append_array(part)
	expected_index += 1
	if expected_index < count:
		return {}
	var decoded := data.decompress(raw_size, FileAccess.COMPRESSION_DEFLATE)
	var complete := decoded.size() == raw_size
	clear()
	return {"bytes": decoded} if complete else {"error": true}
