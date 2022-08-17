extends KinematicBody2D

export var speed = 400
export var max_speed = 600
export var min_speed = 300
export var ramp_threshold = 500
export var jump_speed = -900
export var gravity = 2500

var velocity = Vector2.ZERO

enum States {
	STATIONARY,
	MOVING,
	JUMPING,
	PUSHING,
	FALLING,
	ONRAMP
}

enum Directions {
	LEFT,
	RIGHT
}

onready var state = States.STATIONARY
onready var dir = Directions.LEFT
onready var prev_pos = position

var just_started_flag = false

var prev_state = States.STATIONARY
var prev_speed = 0

var test = 0

func _debug(_delta):
	$State.text = States.keys()[state]
	$Velocity.text = str(velocity.x)
	
	test += 1
	

func _ready():
	pass
	
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
		if is_on_floor():
			velocity.y = jump_speed - velocity.x
			
	if just_started_flag and state != States.STATIONARY:
		just_started_flag = false		

func is_on_ramp():

	if $RampCheck.is_colliding():
		var collision = $RampCheck.get_collider()
		if collision.has_method("world_to_map"):
			var hit_pos = $RampCheck.get_collision_point()
			var tile_pos = collision.world_to_map(hit_pos)
			var tile_id = collision.get_cellv(tile_pos)
			if tile_id == 2:
				state = States.ONRAMP
				gravity = gravity / 2

func game_logic(delta):
	if $Slowdown.is_stopped() and is_on_floor() and state == States.MOVING:
		$Slowdown.start()
	elif state != States.MOVING:
		$Slowdown.stop()
	
	if state != States.FALLING and position.y > prev_pos.y and not is_on_floor():
		state = States.FALLING
		$FallBoost.start()
		
	elif is_on_floor() and state == States.FALLING:
		$FallBoost.stop()	
		state = States.MOVING
	
	if state != States.ONRAMP:
		prev_state = state
		prev_speed = velocity.x
	if state == States.ONRAMP and is_on_floor():
		gravity = gravity * 2
		
	if state == States.ONRAMP and is_on_floor() and velocity.x <= max_speed:
		velocity.x += 10

	if state == States.ONRAMP and not is_on_floor():
		state = prev_state

	prev_pos = position
	
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
	
	if state != States.ONRAMP:
		velocity.x = clamp(velocity.x, min_speed, max_speed)

	velocity = move_and_slide(velocity, Vector2.UP)
	
	if is_on_wall():
		state = States.STATIONARY
		velocity = Vector2.ZERO
		
	if state == States.MOVING and is_on_ramp():
		$Slowdown.stop()

func _physics_process(delta):
	_debug(delta)
	
	get_input()
	if state != States.STATIONARY:
		game_logic(delta)


func _on_PushingCooldown_timeout():
	if state != States.ONRAMP:
		state = States.MOVING

func _on_Slowdown_timeout():
	if velocity.x > min_speed:
		velocity.x = clamp(velocity.x - 20, min_speed, max_speed)
	$Slowdown.start()

func _on_FallBoost_timeout():
	if velocity.x < max_speed:
		velocity.x += 10
