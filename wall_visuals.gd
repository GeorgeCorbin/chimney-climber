extends TileMapLayer

@export var left_a_path: NodePath
@export var left_b_path: NodePath
@export var right_a_path: NodePath
@export var right_b_path: NodePath

# Tile to paint
@export var source_id: int = 4
@export var atlas_coords: Vector2i = Vector2i(0, 0)

# How many tile columns thick the wall should be (INWARD ONLY)
@export var wall_thickness_tiles: int = 2

# Optional: tiny inward nudge to avoid edge rounding seams
@export var inside_nudge_px: float = 0.0

@onready var left_a: Node2D = get_node_or_null(left_a_path)
@onready var left_b: Node2D = get_node_or_null(left_b_path)
@onready var right_a: Node2D = get_node_or_null(right_a_path)
@onready var right_b: Node2D = get_node_or_null(right_b_path)

func _ready() -> void:
	redraw_all()

func _physics_process(_delta: float) -> void:
	# Safe for now; later you can redraw only when walls recycle
	redraw_all()

func redraw_all() -> void:
	clear()
	if left_a: _paint_wall(left_a, true)
	if left_b: _paint_wall(left_b, true)
	if right_a: _paint_wall(right_a, false)
	if right_b: _paint_wall(right_b, false)

func _paint_wall(wall: Node2D, is_left_wall: bool) -> void:
	var cs := wall.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null:
		return

	var rect := cs.shape as RectangleShape2D
	if rect == null:
		return

	# ---- WORLD bounds of collision ----
	var half := rect.size * 0.5
	var top_y := cs.global_position.y - half.y
	var bot_y := cs.global_position.y + half.y

	var left_x := cs.global_position.x - half.x
	var right_x := cs.global_position.x + half.x

	# Inner edge (facing play area)
	var inner_x: float = right_x if is_left_wall else left_x
	inner_x += inside_nudge_px if is_left_wall else -inside_nudge_px

	# ---- Convert vertical span to tile rows ----
	var c_top: Vector2i = local_to_map(to_local(Vector2(inner_x, top_y)))
	var c_bot: Vector2i = local_to_map(to_local(Vector2(inner_x, bot_y)))

	var y0: int = min(c_top.y, c_bot.y)
	var y1: int = max(c_top.y, c_bot.y)

	# ---- Anchor X EXACTLY on inner edge ----
	var base_cell: Vector2i = local_to_map(
		to_local(Vector2(inner_x, cs.global_position.y))
	)

	# ---- Paint INWARD ONLY (never outward) ----
	for y in range(y0, y1 + 1):
		for t in range(wall_thickness_tiles):
			var x: int = base_cell.x - t if is_left_wall else base_cell.x + t
			set_cell(Vector2i(x, y), source_id, atlas_coords)
