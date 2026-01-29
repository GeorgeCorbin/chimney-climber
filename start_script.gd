extends Control

func _ready():
	$VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	#print("ScoreManager loaded:", ScoreManager != null)
	ScoreManager.load()

func _on_play_pressed():
	get_tree().change_scene_to_file("res://game.tscn")
