extends CanvasLayer

signal main_menu
signal restart

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Menu_pressed():
	emit_signal("main_menu")


func _on_Restart_pressed():
	emit_signal("restart")
