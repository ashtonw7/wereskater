extends Sprite


var rng = RandomNumberGenerator.new()

enum Directions {
	LEFT,
	RIGHT
}
var direction
onready var arrow = get_node("Arrow")

export var degree_mult_default = 2.5
export var degree_incr = 2
export var degree_mult = 2.5

signal manual_wipeout
signal update_score

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	direction = rng.randi_range(0, 1)

func start_manual():
	$Update_Score.start()
	$IncrAngle.start()
	$FlipDir.start()
	$DifficultyIncr.start()

func end_manual():
	$Update_Score.stop()
	$IncrAngle.stop()
	$FlipDir.stop()
	$DifficultyIncr.stop()
	$Arrow.rotation_degrees = 0
	degree_mult = degree_mult_default

func get_input():
	if Input.is_action_just_pressed("left"):
		arrow.rotation_degrees -= 20
	elif Input.is_action_just_pressed("right"):
		arrow.rotation_degrees += 20
		
func check_wipeout():
	if arrow.rotation_degrees <= -90 or arrow.rotation_degrees >= 90:
		emit_signal("manual_wipeout")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	get_input()
	check_wipeout()	



func _on_FlipDir_timeout():
	direction = rng.randi_range(0, 1)

func _on_IncrAngle_timeout():
	if direction == Directions.LEFT and arrow.rotation_degrees > -90:
		arrow.rotation_degrees -= degree_incr * degree_mult
	elif direction == Directions.RIGHT and arrow.rotation_degrees < 90:
		arrow.rotation_degrees += degree_incr * degree_mult

func _on_DifficultyIncr_timeout():
	degree_mult += 0.5


func _on_Update_Score_timeout():
	emit_signal("update_score", 100 * int(degree_mult / 1.5))
