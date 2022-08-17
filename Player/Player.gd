extends KinematicBody2D

export var speed = 400
export var max_speed = 600
export var min_speed = 300
export var jump_speed = -400
export var gravity = 2700

var velocity = Vector2.ZERO

enum States {
	STATIONARY,
	MOVING,
	JUMPING,
	PUSHING,
	FALLING
}

enum Directions {
	LEFT,
	RIGHT
}

onready var state = States.STATIONARY
onready var dir = Directions.LEFT
onready var prev_pos = position

var just_started_flag = false

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

func game_logic(delta):
	if $Slowdown.time_left == 0 and int(position.y) == int(prev_pos.y) and state != States.PUSHING:
		$Slowdown.start()
	elif int(position.y) < int(prev_pos.y):
		$Slowdown.stop()
	
	if state != States.FALLING and position.y > prev_pos.y and not is_on_floor():
		state = States.FALLING
		$FallBoost.start()
		
	elif is_on_floor() and state == States.FALLING:
		$FallBoost.stop()	
		state = States.MOVING
	
	prev_pos = position

	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)
	
	if is_on_wall():
		state = States.STATIONARY
		velocity = Vector2.ZERO

func _physics_process(delta):
	_debug(delta)
	
	get_input()
	if state != States.STATIONARY:
		game_logic(delta)


func _on_PushingCooldown_timeout():
	state = States.MOVING

func _on_Slowdown_timeout():
	if velocity.x > min_speed:
		velocity.x = clamp(velocity.x - 20, min_speed, max_speed)
	$Slowdown.start()

func _on_FallBoost_timeout():
	if velocity.x < max_speed:
		velocity.x += 20
