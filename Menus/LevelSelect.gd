extends Button

export var level = 1
signal start_level


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_Level1_pressed():
	emit_signal("start_level", level)
