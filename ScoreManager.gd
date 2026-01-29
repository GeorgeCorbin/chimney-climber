extends Node

# ---- Tuning ----
const SAVE_PATH := "user://save.json"
const PX_PER_METER := 100.0

# ---- Run stats (reset every run) ----
var run_start_y: float = 0.0
var run_best_height_px: float = 0.0
var run_coins: int = 0

# ---- Persistent stats ----
var best_height_px: float = 0.0
var total_coins: int = 0

func start_run() -> void:
	run_best_height_px = 0.0
	run_coins = 0

func end_run() -> void:
	# nothing required here unless you want to finalize something
	pass


func meters_from_px(px: float) -> float:
	return px / PX_PER_METER
	
func height_score() -> int:
	return int(round(meters_from_px(run_best_height_px)))


func reset_run(start_y: float) -> void:
	run_start_y = start_y
	run_best_height_px = 0.0
	run_coins = 0

func update_height(current_y: float) -> void:
	# y decreases as you go up, so height climbed is start_y - current_y
	var h: float = maxf(0.0, run_start_y - current_y)
	if h > run_best_height_px:
		run_best_height_px = h

func add_coin(amount: int = 1) -> void:
	run_coins += amount

func finalize_run_and_save() -> void:
	# update best
	if run_best_height_px > best_height_px:
		best_height_px = run_best_height_px

	# add coins into total
	total_coins += run_coins

	save()

func load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var txt := f.get_as_text()
	f.close()

	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		return

	best_height_px = float(data.get("best_height_px", 0.0))
	total_coins = int(data.get("total_coins", 0))

func save() -> void:
	var data := {
		"best_height_px": best_height_px,
		"total_coins": total_coins
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
