extends Area2D

@export var value: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		ScoreManager.add_coin(value)
		queue_free()
