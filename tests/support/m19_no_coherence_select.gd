extends RefCounted
## M19NoCoherenceSelect — TEST-ONLY select_access double exposing ONLY
## is_targetable (no is_coherent_with). Proves the dispatcher rejects a
## selection-access dependency that cannot prove bundle coherence
## (V03 F-M19-STRICT-001.A: coherence is mandatory, not absence-exempt).

func is_targetable(_i: int) -> bool:
	return true
