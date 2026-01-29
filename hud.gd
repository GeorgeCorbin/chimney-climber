extends CanvasLayer

@onready var height_label: Label = $HeightLabel
@onready var coin_label: Label = $CoinLabel

func _process(_delta: float) -> void:
	var m := ScoreManager.meters_from_px(ScoreManager.run_best_height_px)
	height_label.text = "Run Height: " + str(ScoreManager.height_score())
	coin_label.text = "Coins: %d" % ScoreManager.run_coins
