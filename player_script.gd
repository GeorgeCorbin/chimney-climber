extends CharacterBody2D

@export var gravity: float = 2200.0
@export var jump_up_speed: float = 1400.0
@export var jump_side_speed: float = 900.0
@export var swipe_min_len: float = 60.0   # pixels
@export var swipe_max_time: float = 0.35  # seconds

@export var kill_below_camera: float = 900.0
@onready var cam: Camera2D = get_viewport().get_camera_2d()

var on_left_wall := false
var on_right_wall := false

var touch_start_pos: Vector2
var touch_start_time: float
var tracking_touch := false

@export var left_wall_path: NodePath = ^"../LeftWall"
@export var right_wall_path: NodePath = ^"../RightWall"
@export var wall_to_player_offset: float = 50.0
@export var start_on_left_wall: bool = true
@export var start_offset_from_camera: float = 600.0

@onready var left_wall: Node2D = get_node(left_wall_path) as Node2D
@onready var right_wall: Node2D = get_node(right_wall_path) as Node2D

@export var wall_cling_offset: float = 22.0  # half player width-ish

var was_on_left_wall := false
var was_on_right_wall := false

@export var wall_padding: float = 0.0

@onready var player_cs: CollisionShape2D = $CollisionShape2D
@onready var left_wall_cs: CollisionShape2D = left_wall.get_node("CollisionShape2D") as CollisionShape2D
@onready var right_wall_cs: CollisionShape2D = right_wall.get_node("CollisionShape2D") as CollisionShape2D

func _half_width_from_collision_shape(cs: CollisionShape2D) -> float:
	if cs == null or cs.shape == null:
		push_error("Missing CollisionShape2D or Shape on: " + (cs.name if cs else "null"))
		return 0.0

	var s = cs.shape
	if s is RectangleShape2D:
		return s.size.x * 0.5
	elif s is CapsuleShape2D:
		# capsule width is diameter
		return s.radius
	elif s is CircleShape2D:
		return s.radius
	else:
		push_error("Unsupported shape type: " + s.get_class())
		return 0.0


func _ready():
	var player_half = _half_width_from_collision_shape(player_cs)
	var wall_half = _half_width_from_collision_shape(left_wall_cs)

	self.wall_to_player_offset = player_half + wall_half + wall_padding

	var x: float
	if start_on_left_wall:
		x = left_wall.global_position.x + self.wall_to_player_offset
	else:
		x = right_wall.global_position.x - self.wall_to_player_offset

	var y := 600.0
	if cam:
		y = cam.global_position.y + start_offset_from_camera

	global_position = Vector2(x, y)
	velocity = Vector2.ZERO
	
	ScoreManager.reset_run(global_position.y)


func _physics_process(delta: float) -> void:
	var prev_left = on_left_wall
	var prev_right = on_right_wall

	# Gravity
	velocity.y += gravity * delta

	# Move and collide ONCE
	move_and_slide()

	# Update contact flags
	_update_wall_contact()

	# Snap only on first contact
	var just_left = on_left_wall and not prev_left
	var just_right = on_right_wall and not prev_right

	if just_left:
		global_position.x = left_wall.global_position.x + wall_to_player_offset
	elif just_right:
		global_position.x = right_wall.global_position.x - wall_to_player_offset

	# Wall slide clamp + stop horizontal drift while on wall
	if on_left_wall or on_right_wall:
		velocity.x = 0
		velocity.y = min(velocity.y, 250.0)
		
	ScoreManager.update_height(global_position.y)


	# Kill if too far below camera
	#if cam and global_position.y > cam.global_position.y + kill_below_camera:
		#get_tree().reload_current_scene()
	if cam and global_position.y > cam.global_position.y + kill_below_camera:
		ScoreManager.finalize_run_and_save()
		get_tree().change_scene_to_file("res://death_screen.tscn")


func _unhandled_input(event: InputEvent) -> void:
	# Touch / swipe handling (works on iPhone; emulate touch from mouse for desktop)
	if event is InputEventScreenTouch:
		if event.pressed:
			tracking_touch = true
			touch_start_pos = event.position
			touch_start_time = Time.get_ticks_msec() / 1000.0
		else:
			if tracking_touch:
				tracking_touch = false
				_try_swipe(event.position)

	# Optional: mouse support while testing in editor
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			tracking_touch = true
			touch_start_pos = event.position
			touch_start_time = Time.get_ticks_msec() / 1000.0
		else:
			if tracking_touch:
				tracking_touch = false
				_try_swipe(event.position)

func _try_swipe(end_pos: Vector2) -> void:
	var t = Time.get_ticks_msec() / 1000.0
	var dt = t - touch_start_time
	var delta_pos = end_pos - touch_start_pos

	if dt > swipe_max_time:
		return
	if delta_pos.length() < swipe_min_len:
		return

	# We want mostly upward swipes to trigger jumps
	if delta_pos.y > -20:
		return

	# Decide direction: swipe left or right
	var swipe_left = delta_pos.x < 0
	var swipe_right = delta_pos.x > 0

	# If on a wall, jump to the opposite wall
	if on_left_wall and swipe_right:
		_jump_to_right()
	elif on_right_wall and swipe_left:
		_jump_to_left()
	else:
		# If in air, ignore (or later allow mid-air steering)
		pass

func _jump_to_right():
	on_left_wall = false
	on_right_wall = false
	velocity.y = -jump_up_speed
	velocity.x = jump_side_speed

func _jump_to_left():
	on_left_wall = false
	on_right_wall = false
	velocity.y = -jump_up_speed
	velocity.x = -jump_side_speed

func _update_wall_contact():
	on_left_wall = false
	on_right_wall = false

	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var n := col.get_normal()

		# normal.x > 0 means we hit something on our left
		if n.x > 0.7:
			on_left_wall = true
		elif n.x < -0.7:
			on_right_wall = true
