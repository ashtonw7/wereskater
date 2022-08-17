extends KinematicBody2D

export var speed = 400
export var max_speed = 600
export var min_speed = 300
export var ramp_threshold = 500
export var jump_speed = -200
export var ramp_jump_speed_multiplier = 4
export var gravity = 2500

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

onready var state = States.STATIONARY
onready var dir = Directions.LEFT
onready var prev_pos = position
onready var prev_prev_state = States.STATIONARY

var just_started_flag = false
var hit_ramp_flag = false
var landed_ramp_flag = false

var prev_state = States.STATIONARY
var prev_speed = 0

var test = 0

func _debug(_delta):
	$State.text = States.keys()[state]
	$Velocity.text = str(velocity.x)
	test += 1
	

func _ready():
	pass

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
	
	elif state == States.MOVING and Input.is_action_just_pressed("push"):
		state = States.PUSHING
		velocity.x = clamp(velocity.x + 100, min_speed, max_speed)
		$PushingCooldown.start()
	
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

func handle_landed_ramp():
	if state != States.ONRAMP and is_on_floor_ray() and hit_ramp_flag:
		velocity.x = prev_speed
		hit_ramp_flag = false

func add_gravity(delta):
	if not is_on_floor_ray():
		velocity.y += gravity * delta

func clamp_speed():
	if not hit_ramp_flag:
		velocity.x = clamp(velocity.x, min_speed, max_speed)
		
func handle_wipeout():
	if is_on_ramp_and_valid() and prev_prev_state == States.FALLING:
		state = States.WIPEOUT
		velocity = Vector2.ZERO		
		
	if is_on_wall():
		state = States.WIPEOUT
		velocity = Vector2.ZERO		
				
func game_logic(delta):
	handle_slowdown()
	handle_falling()
	handle_ramp()
	handle_landed_ramp()
	add_gravity(delta)
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
		state = States.MOVING

func _on_Slowdown_timeout():
	if velocity.x > min_speed:
		velocity.x = clamp(velocity.x - 20, min_speed, max_speed)
	$Slowdown.start()

func _on_FallBoost_timeout():
	if velocity.x < max_speed:
		velocity.x += 10
