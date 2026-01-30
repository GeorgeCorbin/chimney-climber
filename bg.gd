extends Node2D

@export var camera_path: NodePath
@onready var cam: Camera2D = get_node(camera_path)

@onready var bgs: Array[Sprite2D] = [
	$BG1 as Sprite2D,
	$BG2 as Sprite2D,
	$BG3 as Sprite2D
]

@export var keep_ahead: float = 1000.0

var step_y: float = 0.0  # spacing between tiles (positive number)

func _ready() -> void:
	# spacing based on your perfect editor placement
	step_y = abs(bgs[0].global_position.y - bgs[1].global_position.y)

	# optional: snap initial to pixel grid
	for s in bgs:
		s.global_position.y = round(s.global_position.y)

func _physics_process(_delta: float) -> void:
	_recycle()

func _recycle() -> void:
	var cam_y := cam.global_position.y

	while true:
		var top := _top_tile()
		var bottom := _bottom_tile()

		# Compute "top edge" using your step spacing (Centered ON assumption)
		var top_edge := top.global_position.y - step_y * 0.5

		# Ensure we have enough background above the camera
		if top_edge <= cam_y - keep_ahead:
			break

		# Move bottom above top by exactly your discovered spacing
		bottom.global_position.y = top.global_position.y - step_y
		bottom.global_position.y = round(bottom.global_position.y)

func _top_tile() -> Sprite2D:
	var t := bgs[0]
	for s in bgs:
		if s.global_position.y < t.global_position.y:
			t = s
	return t

func _bottom_tile() -> Sprite2D:
	var b := bgs[0]
	for s in bgs:
		if s.global_position.y > b.global_position.y:
			b = s
	return b
