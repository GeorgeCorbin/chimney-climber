extends Camera2D

@export var follow_node: NodePath
@export var lerp_speed: float = 6.0

var target: Node2D

func _ready():
	if follow_node != NodePath():
		target = get_node(follow_node)

func _process(delta):
	if target == null:
		return

	# Only move camera upward (endless climber feel)
	var desired_y = min(global_position.y, target.global_position.y)
	global_position.y = lerp(global_position.y, desired_y, 1.0 - exp(-lerp_speed * delta))
