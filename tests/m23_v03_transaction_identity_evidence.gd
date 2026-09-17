extends SceneTree
## M23-C001 V03 — engine-owned transaction identity evidence (F-M23-V02-STRICT-001).
## Gameplay-domain only. Proves the authoritative open-transaction lookup depends on
## engine-owned runtime instance identity, NOT on caller-mutable transaction fields:
##   - a forged fresh same-class object copying A's visible fields cannot commit/cancel
##     and mutates no queue;
##   - authentic A, after its _token_id/_column/_front_batch_id and detached front are
##     maliciously mutated toward B, is STILL recognized as A and commits exactly its
##     ORIGINAL column-0 front once;
##   - B remains independently valid and commits only its own column-1 front;
##   - no wrong-column removal, no orphaning, no extra advance;
##   - consumed/stale/reset tokens fail closed.
##
## Run: godot --headless --path . -s res://tests/m23_v03_transaction_identity_evidence.gd
## Exits 0 on success, 1 on any failure.

const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const BatchSelectionTransaction = preload("res://scripts/gameplay/supply/batch_selection_transaction.gd")
const ColorBatch = preload("res://scripts/gameplay/supply/color_batch.gd")

var _fail := 0

func _initialize() -> void:
	var e = BatchSupplyEngine.create(3, 3)
	e.load_columns([
		[ColorBatch.make("A0", 0, 1, 5), ColorBatch.make("A1", 0, 2, 5)],
		[ColorBatch.make("B0", 1, 3, 5), ColorBatch.make("B1", 1, 4, 5)],
		[ColorBatch.make("Z0", 2, 1, 5)],
	])
	# 1-2: authentic A (col 0) and B (col 1).
	var a = e.begin_front_selection(0)
	var b = e.begin_front_selection(1)
	print("V03 A: token=%d column=%d front=%s iid=%d" % [a.get_token_id(), a.get_column(), a.get_front_batch_id(), a.get_instance_id()])
	print("V03 B: token=%d column=%d front=%s iid=%d" % [b.get_token_id(), b.get_column(), b.get_front_batch_id(), b.get_instance_id()])
	# 3: queue snapshot.
	var snap := str(e.debug_snapshot())

	# 4-5: forged fresh object with A's exact visible values.
	var forged = BatchSelectionTransaction.new(a.get_token_id(), a.get_column(), a.get_front_batch_id(), a.get_front_batch())
	print("V03 forged: token=%d column=%d front=%s iid=%d (distinct iid)" % [forged.get_token_id(), forged.get_column(), forged.get_front_batch_id(), forged.get_instance_id()])
	_ok(not e.commit(forged), "forged copy commit -> false")
	_ok(not e.cancel(forged), "forged copy cancel -> false")
	_ok(not e.has_open_transaction(forged), "forged copy has_open_transaction -> false")
	_ok(str(e.debug_snapshot()) == snap, "queue unchanged after forged attacks")

	# 6-9: maliciously mutate authentic A's visible fields toward B / nonsense.
	a._token_id = b.get_token_id()
	a._column = b.get_column()
	a._front_batch_id = b.get_front_batch_id()
	a._front_batch = b.get_front_batch()
	print("V03 A after mutation: token=%d column=%d front=%s iid=%d (iid immutable)" % [a.get_token_id(), a.get_column(), a.get_front_batch_id(), a.get_instance_id()])

	# 10: A still authentic by engine-owned identity.
	_ok(e.has_open_transaction(a), "field-mutated A still authentic by engine identity")
	# 11: commit(A) advances ONLY A's original column 0 / front A0 once.
	_ok(e.commit(a), "field-mutated A commits")
	_ok(e.get_front(0).get_batch_id() == "A1", "A removed ORIGINAL column-0 front A0 (now A1), not B's front")
	# 12: column 1 unchanged.
	_ok(e.get_front(1).get_batch_id() == "B0" and e.get_remaining(1) == 2, "column 1 byte-for-byte unchanged by mutated-A commit")

	# 13: B independently valid, commits only its own column.
	_ok(e.has_open_transaction(b), "B still open after A commit")
	_ok(e.commit(b), "authentic B commits")
	_ok(e.get_front(1).get_batch_id() == "B1", "B removed original column-1 front B0 exactly once")
	_ok(e.get_front(0).get_batch_id() == "A1", "column 0 unchanged by B commit")

	# 14-15: consumed tokens fail closed.
	_ok(not e.commit(a), "second commit(A) fails closed")
	_ok(not e.cancel(a), "cancel(A) after commit fails closed")
	_ok(not e.commit(b), "second commit(B) fails closed")

	# 16: stale-front and reset-stale remain fail-closed.
	var s1 = e.begin_front_selection(0)
	var s2 = e.begin_front_selection(0)
	_ok(e.commit(s1), "first same-column commit succeeds")
	_ok(not e.commit(s2), "stale-front token fails closed")
	var pre = e.begin_front_selection(1)
	e.reset()
	_ok(not e.commit(pre), "pre-reset token fails closed after reset")
	_ok(e.get_front(0).get_batch_id() == "A0", "reset restored original column-0 front")

	_done()

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M23 V03 transaction identity evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
