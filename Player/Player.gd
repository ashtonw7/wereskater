extends KinematicBody2D

export var speed = 600
export var max_speed = 600
export var min_speed = 300
export var ramp_threshold = 0
export var jump_speed = -800
export var ramp_jump_speed_multiplier = 1
export var gravity = 2500
export var ramp_grav_decr = 0.8
export var werewolf_speed_mult = 1.6
export var flip_slowdown_scale = 0.3
onready var start_pos = position

signal level_complete

var velocity = Vector2.ZERO

enum States {
	STATIONARY,
	MOVING,
	JUMPING,
	FALLING,
	ONRAMP,
	WIPEOUT,
	MANUAL
}

enum Directions {
	LEFT,
	RIGHT
}

enum FlipDirs {
	LEFT,
	DOWN,
	RIGHT,
	UP
}

onready var state = States.STATIONARY
onready var flip_dir = FlipDirs.UP
onready var dir = Directions.LEFT
onready var prev_pos = position
onready var prev_prev_state = States.STATIONARY

onready var sprites = get_node("Sprites")

var rng = RandomNumberGenerator.new()

var just_started_flag = false
var hit_ramp_flag = false
var landed_ramp_flag = false
var picked_flip_letters_flag = false
var next_letter = ''
var curr_letter = 0
var letters = []

var flip_words = ["woah", "flip", "sick", "dope", "cool"]
var prev_flip_word = ""

var werewolf_mode = false

var prev_state = States.STATIONARY
var prev_speed = 0

var flip_count = 1

var score = 0

var test = 0

func _debug(_delta):
	$State.text = States.keys()[state]
	$Velocity.text = str(velocity.x)
	test += 1
	

func _ready():
	rng.randomize()
	$ManualMeter.connect("manual_wipeout", self, "manual_wipeout")
	$ManualMeter.connect("update_score", self, "update_score")
	get_parent().get_node("LevelEnd").get_node("CollisionShape2D").connect("level_end", self, "level_end")


func level_end():
	emit_signal("level_complete", true)

func update_score(add_score):
	score += add_score
	get_parent().get_node("CanvasLayer").get_node("Score").get_node("Score").text = str(score)

func is_on_floor_ray():
	if $GroundCheck.is_colliding():
		return true
	else:
		return false

func start_manual():
	sprites.rotation_degrees = -15
	$ManualMeter.visible = true
	$ManualMeter.start_manual()
	if not get_parent().get_parent().get_node("Heartbeat").playing:
		get_parent().get_parent().get_node("Heartbeat").play()

func end_manual():
	get_parent().get_parent().get_node("Heartbeat").stop()
	sprites.rotation_degrees = 0	
	$ManualMeter.visible = false
	$ManualMeter.end_manual()
	
func check_end_manual():
	if state == States.MANUAL and not is_on_floor_ray():
		end_manual()
	
func manual_wipeout():
	state = States.WIPEOUT
	handle_wipeout()

func get_input():
	if state == States.STATIONARY and Input.is_action_just_pressed("start"):
		$Start.visible = false
		state = States.MOVING
		velocity.x = speed
		$TimeScore.start()
		just_started_flag = true
	
	elif Input.is_action_just_pressed("down") and state == States.MOVING and is_on_floor_ray():
		state = States.MANUAL
		start_manual()
	elif Input.is_action_just_pressed("down") and state == States.MANUAL and is_on_floor_ray():
		state = States.MOVING
		end_manual()
	
	if Input.is_action_just_pressed("jump") and not just_started_flag:
		if is_on_floor_ray():
			velocity.y = jump_speed
			
	if just_started_flag and state != States.STATIONARY:
		just_started_flag = false		

func enter_werewolf_mode():
	werewolf_mode = true
	sprites.get_node("Player").visible = false
	sprites.get_node("Werewolf").visible = true

	$ManualMeter.degree_incr = 2.5
	$Camera2D.offset.x = -200

func is_on_ramp():
	if is_on_floor_ray() and position.y < prev_pos.y:
		var collision = $GroundCheck.get_collider()
		if collision.has_method("world_to_map"):
			var hit_pos = $GroundCheck.get_collision_point()
			var tile_pos = collision.world_to_map(hit_pos)
			var tile_id = collision.get_cellv(tile_pos)
			if tile_id == 2:
				return true
	return false

func is_on_ramp_and_valid():
	if not werewolf_mode:
		return position.y < prev_pos.y and is_on_ramp() and velocity.x >= ramp_threshold and state != States.WIPEOUT
	else:
		return position.y < prev_pos.y and is_on_ramp() and velocity.x <= ramp_threshold * -1 and state != States.WIPEOUT

func handle_slowdown():
	pass

func handle_falling():
	if state != States.FALLING and position.y > prev_pos.y and not is_on_floor_ray():
		state = States.FALLING

	elif is_on_floor_ray() and state == States.FALLING:
		state = States.MOVING

func update_prevs():
	if state != States.ONRAMP:
		prev_prev_state = prev_state
		prev_state = state
		prev_speed = velocity.x
	prev_pos = position	
	
func handle_ramp():
	if is_on_ramp_and_valid() and state != States.ONRAMP:
		if state == States.MANUAL:
			end_manual()
		state = States.ONRAMP
		if not werewolf_mode:
			sprites.rotation_degrees = -35
			sprites.rotation_degrees = -35
			sprites.rotation_degrees = -35
		else:
			sprites.rotation_degrees = 35
			sprites.rotation_degrees = 35
			sprites.rotation_degrees = 35
		hit_ramp_flag = true

	if not is_on_floor_ray() and hit_ramp_flag and velocity.y >= 0 and state != States.FALLING:
		velocity.y = jump_speed * ramp_jump_speed_multiplier
		gravity = gravity * ramp_grav_decr

func handle_landed_ramp():
	if state != States.ONRAMP and is_on_floor_ray() and hit_ramp_flag:
		sprites.rotation_degrees = 0
		sprites.rotation_degrees = 0
		sprites.rotation_degrees = 0
		get_parent().get_parent().get_node("Heartbeat").stop()
		get_parent().get_parent().get_node("BGM").volume_db = -6.118
		reset_flip_letters()
		flip_count = 1
		velocity.x = prev_speed
		gravity = gravity / ramp_grav_decr
		hit_ramp_flag = false
		Engine.time_scale = 1

func add_gravity(delta):
	if not is_on_floor_ray():
		velocity.y += gravity * delta

func clamp_speed():
	if not hit_ramp_flag:
		if not werewolf_mode:
			velocity.x = clamp(velocity.x, max_speed, max_speed)			
		else:
			velocity.x = clamp(velocity.x, max_speed * werewolf_speed_mult * -1, max_speed * werewolf_speed_mult * -1)
		
func check_wipeout():
#	if is_on_ramp_and_valid() and prev_prev_state == States.FALLING:
#		state = States.WIPEOUT
		
	if is_on_wall():
		state = States.WIPEOUT
		
	if is_on_floor() and flip_dir != FlipDirs.UP:
		state = States.WIPEOUT

func reset_flip_letters():
	$LetterSquare1.visible = false
	$LetterSquare2.visible = false
	$LetterSquare3.visible = false
	$LetterSquare4.visible = false
	
	$LetterSquare1.color = Color(0, 0, 1, 1)
	$LetterSquare2.color = Color(0, 0, 1, 1)
	$LetterSquare3.color = Color(0, 0, 1, 1)
	$LetterSquare4.color = Color(0, 0, 1, 1)

func reset_player():
	$TimeScore.stop()
	get_parent().get_parent().get_node("Heartbeat").stop()
	get_parent().get_parent().get_node("BGM").volume_db = -6.118
	sprites.get_node("Werewolf").visible = false
	sprites.get_node("Player").visible = true
	score = 0
	flip_count = 1
	Engine.time_scale = 1
	sprites.rotation = 0
	hit_ramp_flag = false
	flip_dir = FlipDirs.UP
	$FlipLabel.text = ""
	$ManualMeter.degree_incr = 2.5
	reset_flip_letters()
	
	$ManualMeter.visible = false	
	$ManualMeter.end_manual()

	
	$Camera2D.offset.x = 200
	
	velocity = Vector2.ZERO
	werewolf_mode = false
	position = start_pos
	$Start.visible = true
	state = States.STATIONARY
	
	curr_letter = 0
	letters = []
		
func handle_wipeout():
	if state == States.WIPEOUT:
		reset_player()
		emit_signal("level_complete", false)

func get_rand_flip_word():
	var flip_word = flip_words[rng.randi() % len(flip_words)]
	while flip_word == prev_flip_word:
		flip_word = flip_words[rng.randi() % len(flip_words)]
	return flip_word
	

func handle_flips():
	if not is_on_floor_ray() and hit_ramp_flag:
		if not get_parent().get_parent().get_node("Heartbeat").playing:
			get_parent().get_parent().get_node("Heartbeat").play()
			get_parent().get_parent().get_node("BGM").volume_db = -15
		Engine.time_scale = flip_slowdown_scale
		
		if not picked_flip_letters_flag:
			picked_flip_letters_flag = true
			reset_flip_letters()
			var flip_word = get_rand_flip_word()
			prev_flip_word = flip_word
			var letter1 = flip_word[0]
			var letter2 = flip_word[1]
			var letter3 = flip_word[2]
			var letter4 = flip_word[3]
			
			$LetterSquare1.get_node("Label").text = letter1
			$LetterSquare2.get_node("Label").text = letter2
			$LetterSquare3.get_node("Label").text = letter3
			$LetterSquare4.get_node("Label").text = letter4
			
			$LetterSquare1.visible = true
			$LetterSquare2.visible = true
			$LetterSquare3.visible = true
			$LetterSquare4.visible = true
			
			letters = [letter1, letter2, letter3, letter4]
			curr_letter = 0
			next_letter = letters[curr_letter]
		
		if Input.is_action_just_pressed(next_letter) and flip_dir == FlipDirs.UP:
			get_node("LetterSquare" + str(curr_letter + 1)).color = Color(0, 1, 0, 1)
			flip_dir = FlipDirs.LEFT
			sprites.rotation_degrees = -90
			
			curr_letter += 1
			next_letter = letters[curr_letter % len(letters)]
			get_parent().get_parent().get_node("Thump").play()
			
		elif Input.is_action_just_pressed(next_letter) and flip_dir == FlipDirs.LEFT:
			get_node("LetterSquare" + str(curr_letter + 1)).color = Color(0, 1, 0, 1)
			flip_dir = FlipDirs.DOWN
			sprites.rotation_degrees = -180

			curr_letter += 1
			next_letter = letters[curr_letter % len(letters)]
			get_parent().get_parent().get_node("Thump").play()			
			
		elif Input.is_action_just_pressed(next_letter) and flip_dir == FlipDirs.DOWN:
			get_node("LetterSquare" + str(curr_letter + 1)).color = Color(0, 1, 0, 1)
			flip_dir = FlipDirs.RIGHT
			sprites.rotation_degrees = -270

			curr_letter += 1
			next_letter = letters[curr_letter % len(letters)]
			get_parent().get_parent().get_node("Thump").play()
						
		elif Input.is_action_just_pressed(next_letter) and flip_dir == FlipDirs.RIGHT:
			get_node("LetterSquare" + str(curr_letter + 1)).color = Color(0, 1, 0, 1)
			flip_dir = FlipDirs.UP
			sprites.rotation_degrees = 0
			
			update_score(500 * flip_count / 2)
			flip_count += 1
			
			curr_letter += 1
			next_letter = letters[curr_letter % len(letters)]
			get_parent().get_parent().get_node("Thump").play()
			picked_flip_letters_flag = false

	else:
		picked_flip_letters_flag = false
		curr_letter = 0
		letters = []
		
		$FlipLabel.text = ""
				
func game_logic(delta):
	check_end_manual()
	handle_falling()
	handle_ramp()
	handle_landed_ramp()
	handle_flips()
	add_gravity(delta)
	check_wipeout()
	handle_wipeout()

	if werewolf_mode and velocity.x > 0:
		velocity.x *= werewolf_speed_mult * -1
	clamp_speed()
	update_prevs()
	
	velocity = move_and_slide(velocity, Vector2.UP)

func _physics_process(delta):
	_debug(delta)
	
	if state == States.MOVING or state == States.MANUAL or is_on_floor_ray() and state == States.ONRAMP:
		if not get_parent().get_parent().get_node("Skate").playing:
			get_parent().get_parent().get_node("Skate").play()
	else:
		get_parent().get_parent().get_node("Skate").stop()
	
	get_input()
	if state != States.STATIONARY and state != States.WIPEOUT:
		game_logic(delta)


func _on_PushingCooldown_timeout():
	if state == States.PUSHING:
		pass


func _on_TimeScore_timeout():
	update_score(50)
