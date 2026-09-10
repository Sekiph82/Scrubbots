extends "res://scripts/gameplay/agents/scrubbot_agent.gd"
## M19ResetCancelAgent — TEST-ONLY ScrubbotAgent subclass whose cancel() can
## synchronously call dispatcher.reset() (nested reset) and/or free itself, to
## prove reset re-entry safety and post-cancel instance revalidation
## (F-M19-STRICT-003.E). Preload it (AL-001).

var dispatcher = null          ## if set, cancel() calls dispatcher.reset() (nested)
var cancel_counter = null      ## optional Array [int]; incremented per cancel (survives self-free)
var free_self: bool = false    ## if true, cancel() frees this agent immediately

func cancel() -> void:
	if cancel_counter != null:
		cancel_counter[0] += 1
	if dispatcher != null:
		dispatcher.reset() # nested reset while the outer reset runs -> must no-op
	if free_self:
		free() # immediate self-free; return before touching any member/super
		return
	super.cancel()
