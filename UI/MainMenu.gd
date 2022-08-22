extends Control


signal start_level


# Called when the node enters the scene tree for the first time.
func start_level(level):
	emit_signal("start_level", level)

func _ready():
	$Level1.connect("start_level", self, "start_level")
	$Level2.connect("start_level", self, "start_level")
	$Level3.connect("start_level", self, "start_level")
	$Level4.connect("start_level", self, "start_level")
	$Level5.connect("start_level", self, "start_level")
