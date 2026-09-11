extends "res://scripts/gameplay/targeting/color_candidate_index.gd"
## M20 V02 test double — a REAL ColorCandidateIndex subclass (so `is
## ColorCandidateIndex` and is_bound_to() stay genuine) exposing adversarial
## callback seams for the mutation-sensitive rollback matrix (F-M20-STRICT-004/009):
##   - mode "mutate_false":     perform the real CLEARED removal, then return false.
##   - mode "true_noop":        return true WITHOUT removing (lying success).
##   - mode "neutralize_false": neutralize/unbind the cache, then return false.
##   - mode "normal":           delegate to the real implementation.
## `sync_hook` fires once at the top of sync_cell (inject nested arrival /
## activation / reset); `coherence_hook` fires once inside is_bound_to (inject a
## bind/activation-time callback). Both are one-shot so a re-entrant drain of a
## second arrival is not re-hooked.
var mode: String = "normal"
var sync_hook: Callable = Callable()
var coherence_hook: Callable = Callable()
var _sync_hook_fired: bool = false
var _coh_hook_fired: bool = false
## For mode "unrelated_loss" (V03 §3 candidate unrelated-loss mutate-false):
## after removing the target, also drop an UNRELATED same-color candidate from the
## bucket, then return false — collateral candidate loss.
var loss_color: int = -1
var loss_index: int = -1

func is_bound_to(board) -> bool:
	if coherence_hook.is_valid() and not _coh_hook_fired:
		_coh_hook_fired = true
		coherence_hook.call()
	return super.is_bound_to(board)

func sync_cell(index: int) -> bool:
	if sync_hook.is_valid() and not _sync_hook_fired:
		_sync_hook_fired = true
		sync_hook.call(index)
	match mode:
		"mutate_false":
			super.sync_cell(index) # real removal for the mutated target
			return false
		"unrelated_loss":
			super.sync_cell(index)            # real removal for the target
			_bucket_remove(loss_color, loss_index) # collateral: drop unrelated U
			return false
		"true_noop":
			return true # lie: claims success without removing the target
		"neutralize_false":
			_neutralize() # drift/unbind before reporting failure
			return false
		_:
			return super.sync_cell(index)
