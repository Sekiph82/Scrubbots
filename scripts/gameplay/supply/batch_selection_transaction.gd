extends RefCounted
## BatchSelectionTransaction — M23 two-phase front-selection token. Preload this
## script (res://scripts/gameplay/supply/batch_selection_transaction.gd).
##
## Returned by BatchSupplyEngine.begin_front_selection(); passed back to commit()
## or cancel(). It does NOT pop the queue. It binds the exact originating column and
## the exact selected front batch identity/version at begin time so a stale,
## cross-column, double or forged commit fails closed inside the engine. The engine
## validates the token by its private id against its live open-token set; this
## object only carries immutable selection facts for the caller.

var _token_id: int = -1
var _column: int = -1
var _front_batch_id: String = ""
var _front_batch  # detached ColorBatch copy of the selected front (for the caller)

func _init(token_id: int, column: int, front_batch_id: String, front_batch) -> void:
	_token_id = token_id
	_column = column
	_front_batch_id = front_batch_id
	_front_batch = front_batch

func get_token_id() -> int:
	return _token_id

func get_column() -> int:
	return _column

func get_front_batch_id() -> String:
	return _front_batch_id

## Detached copy of the front batch this selection points at.
func get_front_batch():
	return _front_batch
