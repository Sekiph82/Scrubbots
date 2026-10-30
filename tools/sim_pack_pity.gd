extends SceneTree
## SB-M43-R07-001/006 — earned-pack pity + First Collection Sprint balance simulation (offline tool).
##
##   godot --headless --path . -s res://tools/sim_pack_pity.gd [-- --seeds=200 --lpd=4 --loss=0.15]
##
## Drives the REAL EconomyServices graph (config, WinStreakService -> GiftMeterService claims,
## DailyService login claims, PendingPackQueue, CardPackService / CollectionInventory / PackPity
## draw code) for a simulated fresh player, once per (threshold, first_sprint_threshold) candidate
## written into a temp copy of data/config/economy_rewards_v1.json. Pack sources are exactly the
## configured ones (Gift Meter milestones fed by first-clear win-streak SB, Daily login cycle);
## ad-gated Rewarded Daily packs, events and comeback gifts are excluded (conservative).
## Feature unlock levels come from data/config/feature_unlocks_v1.json: Daily claims start at
## the `daily` frontier, earned packs stay queued until the `card_packs` frontier (factory 066).
##
## Player model ("ordinarily engaged"): plays `lpd` new levels per local day and claims Daily and
## every Gift milestone; each attempt is lost with probability `loss` (loss resets the streak, the
## level is retried). Reported "level" = the last level cleared when the event happened.
## Read-only: writes only user:// temp configs, prints the table, changes no repository file.

const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const CONFIG := "res://data/config/economy_rewards_v1.json"
const UNLOCKS := "res://data/config/feature_unlocks_v1.json"
const MAX_LEVEL := 600
## [threshold, first_sprint_threshold]; 0 = off.
const CANDIDATES := [[0, 0], [2, 0], [3, 0], [4, 0], [5, 0], [6, 0], [3, 1], [3, 2], [3, 3], [2, 1], [4, 1]]

var _day := 0

func _initialize() -> void:
	var args := {"seeds": 200, "lpd": 4, "loss": 0.15}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=")
		if kv.size() == 2 and args.has(kv[0]):
			args[kv[0]] = float(kv[1])
	var unlocks: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(UNLOCKS))["unlocks"]
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	print("seeds=%d levels/day=%d loss=%.2f daily@%d packs@%d" % [args.seeds, args.lpd, args.loss, unlocks.daily, unlocks.card_packs])
	print("| threshold | sprint | Set 1 p10 | p50 | p90 | by L40 | cards@L40 p50 | full p10 | full p50 | full p90 | max dry packs |")
	print("|---|---|---|---|---|---|---|---|---|---|---|")
	for c in CANDIDATES:
		var cfg: Dictionary = base.duplicate(true)
		cfg["collection"]["pity"] = {"threshold": c[0], "first_sprint_threshold": c[1]}
		var path := "user://sim_pack_pity_%d_%d_%d.json" % [OS.get_process_id(), c[0], c[1]]
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(cfg))
		f.close()
		var s1: Array = []
		var full: Array = []
		var own40: Array = []
		var dry := 0
		for seed in range(int(args.seeds)):
			var r := _run(path, seed, int(args.lpd), float(args.loss), int(unlocks.daily), int(unlocks.card_packs))
			s1.append(r.set1)
			full.append(r.full)
			own40.append(r.own40)
			dry = max(dry, r.dry)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		var by40 := s1.filter(func(x): return x <= 40).size() * 100.0 / s1.size()
		print("| %s | %s | %d | %d | %d | %.0f%% | %d | %d | %d | %d | %d |" % [_off(c[0]), _off(c[1]), _q(s1, 0.1), _q(s1, 0.5), _q(s1, 0.9), by40,
			_q(own40, 0.5), _q(full, 0.1), _q(full, 0.5), _q(full, 0.9), dry])
	quit(0)

func _run(path: String, seed: int, lpd: int, loss: float, daily_at: int, packs_at: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var player := RandomNumberGenerator.new()
	player.seed = seed * 7919 + 1
	_day = 0
	var e = EconomyServices.new(path, func(): return 1800000000 + _day * 86400, rng, func(): return 20000 + _day)
	assert(e.config.is_ok(), e.config.get_error())
	var out := {"set1": MAX_LEVEL, "full": MAX_LEVEL, "own40": 0, "dry": 0}
	var level := 1
	while level <= MAX_LEVEL:
		for _i in range(lpd):
			if level >= daily_at:
				e.daily.claim_login()
			while player.randf() < loss:
				e.streak.on_progression_loss()
			var won: Dictionary = e.streak.process_first_clear_win(level)
			for occ in won.get("gift_milestones", []):
				e.gift.claim(occ["id"], e.reward, e.config)
			if level + 1 >= packs_at:
				while e.pending_packs.size() > 0:
					var p: Dictionary = e.pending_packs.front()
					if p["kind"] == "premium":
						e.packs.open_premium()
					else:
						e.packs.open_standard()
					e.pending_packs.remove(p["id"])
					if e.pack_pity.focus_set(e.collection) == 0 and not e.collection.first_missing_eligible_card().is_empty():
						out.dry = max(out.dry, e.pack_pity.count())
			if out.set1 == MAX_LEVEL and e.collection.is_set_complete(1):
				out.set1 = level
			if level == 40:
				out.own40 = e.collection.all_card_ids().filter(func(cid): return e.collection.owned(cid) > 0).size()
			if e.collection.completed_set_count() == 15:
				out.full = level
				e.dispose()
				return out
			level += 1
		_day += 1
	e.dispose()
	return out

static func _q(a: Array, p: float) -> int:
	var s := a.duplicate()
	s.sort()
	return int(s[int(p * (s.size() - 1))])

static func _off(v: int) -> String:
	return str(v) if v > 0 else "off"
