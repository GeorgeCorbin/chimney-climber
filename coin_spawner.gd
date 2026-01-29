extends Node2D

@export var coin_scene: PackedScene
@export var camera_path: NodePath = ^"../Camera2D"  # adjust if needed

# spawn tuning
@export var spawn_ahead: float = 1200.0   # how far above camera to spawn
@export var spawn_spacing_min: float = 260.0
@export var spawn_spacing_max: float = 520.0

# chimney bounds (set these to match your playable gap)
@export var min_x: float = 200.0
@export var max_x: float = 880.0

@onready var cam: Camera2D = get_node(camera_path) as Camera2D

var next_spawn_y: float

func _ready() -> void:
	if coin_scene == null:
		push_error("CoinSpawner: assign coin_scene in Inspector!")
		return

	# first spawn target a bit above the camera
	next_spawn_y = cam.global_position.y - spawn_ahead

func _process(_delta: float) -> void:
	if coin_scene == null or cam == null:
		return

	# If camera moved up enough, keep spawning further up
	while next_spawn_y > cam.global_position.y - spawn_ahead:
		_spawn_coin_at(next_spawn_y)
		next_spawn_y -= randf_range(spawn_spacing_min, spawn_spacing_max)

func _spawn_coin_at(y: float) -> void:
	var coin := coin_scene.instantiate() as Node2D
	coin.global_position = Vector2(randf_range(min_x, max_x), y)
	get_tree().current_scene.add_child(coin)
