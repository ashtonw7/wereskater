extends KinematicBody2D

export var speed = 600
export var max_speed = 600
export var min_speed = 300
export var ramp_threshold = 0
export var jump_speed = -200
export var ramp_jump_speed_multiplier = 4
export var gravity = 2500
export var ramp_grav_decr = 0.8
onready var start_pos = position

var velocity = Vector2.ZERO

enum States {
	STATIONARY,
	MOVING,
	JUMPING,
	PUSHING,
	FALLING,
	ONRAMP,
	WIPEOUT
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

var rng = RandomNumberGenerator.new()

var just_started_flag = false
var hit_ramp_flag = false
var landed_ramp_flag = false
var picked_flip_letters_flag = false
var next_letter = ''
var curr_letter = 0
var letters = []

var prev_state = States.STATIONARY
var prev_speed = 0

var test = 0

func _debug(_delta):
	$State.text = States.keys()[state]
	$Velocity.text = str(velocity.x)
	test += 1
	

func _ready():
	rng.randomize()

func is_on_floor_ray():
	if $GroundCheck.is_colliding():
		return true
	else:
		return false
	
func get_input():
	if state == States.STATIONARY and Input.is_action_just_pressed("start"):
		state = States.PUSHING
		$PushingCooldown.start()
		velocity.x = speed
		just_started_flag = true
	
	elif Input.is_action_just_pressed("push") and state == States.MOVING and is_on_floor_ray():
#		state = States.PUSHING
#		velocity.x = clamp(velocity.x + 50, min_speed, max_speed)
#		$PushingCooldown.start()
		pass
	
	if Input.is_action_just_pressed("jump") and not just_started_flag:
		if is_on_floor_ray():
			velocity.y = jump_speed - velocity.x
			
	if just_started_flag and state != States.STATIONARY:
		just_started_flag = false		

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
	return position.y < prev_pos.y and is_on_ramp() and velocity.x >= ramp_threshold and state != States.WIPEOUT

func handle_slowdown():
	if $Slowdown.is_stopped() and is_on_floor_ray() and state == States.MOVING:
		$Slowdown.start()
	elif state != States.MOVING:
		$Slowdown.stop()

func handle_falling():
	if state != States.FALLING and position.y > prev_pos.y and not is_on_floor_ray():
		state = States.FALLING
		$FallBoost.start()	
	elif is_on_floor_ray() and state == States.FALLING:
		$FallBoost.stop()	
		state = States.MOVING

func update_prevs():
	if state != States.ONRAMP:
		prev_prev_state = prev_state
		prev_state = state
		prev_speed = velocity.x
	prev_pos = position	
	
func handle_ramp():
	if is_on_ramp_and_valid() and state != States.ONRAMP:
		$Slowdown.stop()
		state = States.ONRAMP
		hit_ramp_flag = true
	if not is_on_floor_ray() and hit_ramp_flag and velocity.y >= 0 and state != States.FALLING:
		velocity.y = jump_speed * ramp_jump_speed_multiplier
		gravity = gravity * ramp_grav_decr

func handle_landed_ramp():
	if state != States.ONRAMP and is_on_floor_ray() and hit_ramp_flag:
		velocity.x = prev_speed
		gravity = gravity / ramp_grav_decr
		hit_ramp_flag = false
		Engine.time_scale = 1

func add_gravity(delta):
	if not is_on_floor_ray():
		velocity.y += gravity * delta

func clamp_speed():
	if not hit_ramp_flag:
		velocity.x = clamp(velocity.x, max_speed, max_speed)
#		velocity.x = clamp(velocity.x, min_speed, max_speed)
		
func check_wipeout():
	if is_on_ramp_and_valid() and prev_prev_state == States.FALLING:
		state = States.WIPEOUT
		
	if is_on_wall():
		state = States.WIPEOUT
		
	if is_on_floor() and flip_dir != FlipDirs.UP:
		state = States.WIPEOUT

func reset_player():
	Engine.time_scale = 1
	$Sprite.rotation = 0
	hit_ramp_flag = false
	flip_dir = FlipDirs.UP
	$FlipLabel.text = ""
	
	$Slowdown.stop()
	$FallBoost.stop()
	
	velocity = Vector2.ZERO
	position = start_pos
	state = States.STATIONARY
	
	curr_letter = 0
	letters = []
		
func handle_wipeout():
	if state == States.WIPEOUT:
		reset_player()

func get_rand_letter():
	return char(rng.randi_range(97, 122))

func handle_flips():
	if not is_on_floor_ray() and hit_ramp_flag:
		Engine.time_scale = 0.3
		
		if not picked_flip_letters_flag:
			picked_flip_letters_flag = true
			var letter1 = get_rand_letter()
			var letter2 = get_rand_letter()
			var letter3 = get_rand_letter()
			var letter4 = get_rand_letter()
			letters = [letter1, letter2, letter3, letter4]
			curr_letter = 0
			next_letter = letters[curr_letter]
			
			var strlabel = ""
			for letter in letters:
				strlabel += letter + " "
			$FlipLabel.text = strlabel
		
		if Input.is_action_just_pressed(next_letter) and flip_dir == FlipDirs.UP:
			flip_dir = FlipDirs.LEFT
			$Sprite.rotation_degrees = -90
			
			curr_letter += 1
			next_letter = letters[curr_letter % len(letters)]
			
		elif Input.is_action_just_pressed(next_letter) and flip_dir == FlipDirs.LEFT:
			flip_dir = FlipDirs.DOWN
			$Sprite.rotation_degrees = -180

			curr_letter += 1
			next_letter = letters[curr_letter % len(letters)]
			
		elif Input.is_action_just_pressed(next_letter) and flip_dir == FlipDirs.DOWN:
			flip_dir = FlipDirs.RIGHT
			$Sprite.rotation_degrees = -270

			curr_letter += 1
			next_letter = letters[curr_letter % len(letters)]
			
		elif Input.is_action_just_pressed(next_letter) and flip_dir == FlipDirs.RIGHT:
			flip_dir = FlipDirs.UP
			$Sprite.rotation_degrees = 0
			
			curr_letter += 1
			next_letter = letters[curr_letter % len(letters)]
			picked_flip_letters_flag = false

	else:
		picked_flip_letters_flag = false
		curr_letter = 0
		letters = []
		
		$FlipLabel.text = ""
				
func game_logic(delta):
	handle_slowdown()
	handle_falling()
	handle_ramp()
	handle_landed_ramp()
	handle_flips()
	add_gravity(delta)
	check_wipeout()
	handle_wipeout()
	
	clamp_speed()
	update_prevs()

	velocity = move_and_slide(velocity, Vector2.UP)

func _physics_process(delta):
	_debug(delta)
	
	get_input()
	if state != States.STATIONARY and state != States.WIPEOUT:
		game_logic(delta)


func _on_PushingCooldown_timeout():
	if state == States.PUSHING:
		pass
#		state = States.MOVING

func _on_Slowdown_timeout():
	if velocity.x > min_speed:
		velocity.x = clamp(velocity.x - 20, min_speed, max_speed)
	$Slowdown.start()

func _on_FallBoost_timeout():
	if velocity.x < max_speed:
		velocity.x += 10
