extends RefCounted
## M19SelectAccessVariants — TEST-ONLY configurable select_access double. Preload
## it (AL-001). Exercises the mandatory-coherence bind boundary
## (V03 F-M19-STRICT-001.A):
##   - always exposes is_targetable;
##   - exposes is_coherent_with whose verdict is configurable (bool true/false or
##     a non-bool value) to prove non-bool and false verdicts fail bind.
## The missing-method case is covered by a separate double with no
## is_coherent_with at all (see m19_no_coherence_select.gd).

## Set to true (accepted), false (rejected), or a non-bool such as 1 (rejected).
var coherence_value = true

func is_targetable(_i: int) -> bool:
	return true

func is_coherent_with(_a, _b, _c):
	return coherence_value
