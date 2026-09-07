extends RefCounted
## Test double: a partial fake that exposes a configure() method but is NOT a
## real BoardRenderer. GameplaySession.bind_renderer() must reject it fail-closed
## (F-M11-STRICT-002) and never call configure().

var configure_calls: int = 0

func configure(_board, _palette, _available_size) -> void:
	configure_calls += 1
