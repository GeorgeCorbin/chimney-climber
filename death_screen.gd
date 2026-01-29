extends Control

@onready var run_height: Label = $VBoxContainer/RunHeightLabel
@onready var run_coins: Label = $VBoxContainer/RunCoinsLabel
@onready var best_height: Label = $VBoxContainer/BestHeightLabel
@onready var total_coins: Label = $VBoxContainer/TotalCoinsLabel

func _ready():
	$VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)
	$VBoxContainer/MenuButton.pressed.connect(_on_menu_pressed)
	
	var run_m := ScoreManager.meters_from_px(ScoreManager.run_best_height_px)
	var best_m := ScoreManager.meters_from_px(ScoreManager.best_height_px)

	run_height.text = "Run Height: %d" % run_m
	run_coins.text = "Run Coins: %d" % ScoreManager.run_coins
	best_height.text = "Best Height: %d" % best_m
	total_coins.text = "Total Coins: %d" % ScoreManager.total_coins

func _on_restart_pressed():
	ScoreManager.start_run()
	get_tree().change_scene_to_file("res://game.tscn")

func _on_menu_pressed():
	ScoreManager.start_run() # resets run stats so menu doesn't show old run
	get_tree().change_scene_to_file("res://startmenu.tscn")
