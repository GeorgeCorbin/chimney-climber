extends Node2D

@export var extra_margin: float = 300.0

@export var left_a_path: NodePath
@export var left_b_path: NodePath
@export var right_a_path: NodePath
@export var right_b_path: NodePath
@export var player_path: NodePath

@onready var left_a: Node2D = get_node(left_a_path)
@onready var left_b: Node2D = get_node(left_b_path)
@onready var right_a: Node2D = get_node(right_a_path)
@onready var right_b: Node2D = get_node(right_b_path)
@onready var player: Node2D = get_node(player_path)

@export var keep_ahead: float = 1000.0  # how much wall should exist above player

var seg_h: float = 0.0

func _ready():
	seg_h = _get_wall_height(left_a)
	_stack_pair(left_a, left_b)
	_stack_pair(right_a, right_b)

	# prefill ahead so you can't start near a seam
	_recycle_pair(left_a, left_b)
	_recycle_pair(right_a, right_b)


func _physics_process(_delta):
	_recycle_pair(left_a, left_b)
	_recycle_pair(right_a, right_b)

func _recycle_pair(a: Node2D, b: Node2D) -> void:
	while true:
		# Top segment = one with smaller center y (higher up)
		var top := a if _cs_center_y(a) < _cs_center_y(b) else b
		var other := b if top == a else a

		# If the top edge is not far enough above the player, stack "other" above it
		var top_edge := _top_edge_y(top)

		# Remember: up is negative y. "Above player" means smaller y than player.
		# We want: top_edge <= player_y - keep_ahead
		if top_edge <= player.global_position.y - keep_ahead:
			break

		var desired_center_y := _cs_center_y(top) - seg_h
		_move_wall_to_cs_center_y(other, desired_center_y)


func _stack_pair(a: Node2D, b: Node2D) -> void:
	var desired_center_y := _cs_center_y(a) - seg_h
	_move_wall_to_cs_center_y(b, desired_center_y)

# --- Collision-shape based helpers (robust even if CollisionShape2D is offset) ---

func _get_rect_shape(wall: Node2D) -> RectangleShape2D:
	var cs := wall.get_node("CollisionShape2D") as CollisionShape2D
	if cs == null or cs.shape == null:
		push_error("Wall missing CollisionShape2D/shape: " + wall.name)
		return null
	var rect := cs.shape as RectangleShape2D
	if rect == null:
		push_error("Wall shape must be RectangleShape2D: " + wall.name)
		return null
	return rect
	
func _top_edge_y(wall: Node2D) -> float:
	var cs := wall.get_node("CollisionShape2D") as CollisionShape2D
	var rect := _get_rect_shape(wall)
	return cs.global_position.y - rect.size.y * 0.5


func _get_wall_height(wall: Node2D) -> float:
	var rect := _get_rect_shape(wall)
	return rect.size.y if rect != null else 0.0

func _cs_center_y(wall: Node2D) -> float:
	var cs := wall.get_node("CollisionShape2D") as CollisionShape2D
	return cs.global_position.y

func _bottom_edge_y(wall: Node2D) -> float:
	var cs := wall.get_node("CollisionShape2D") as CollisionShape2D
	var rect := _get_rect_shape(wall)
	return cs.global_position.y + rect.size.y * 0.5

func _move_wall_to_cs_center_y(wall: Node2D, desired_cs_y: float) -> void:
	var cs := wall.get_node("CollisionShape2D") as CollisionShape2D
	var delta := desired_cs_y - cs.global_position.y
	wall.global_position.y += delta
