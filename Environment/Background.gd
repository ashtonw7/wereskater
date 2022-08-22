extends ColorRect

onready var player = get_parent().get_node("Player")
onready var end_pos = get_parent().get_node("WerewolfMode").position.x

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if get_parent().has_node("Player"):
		modulate.a = (255 - (player.position.x / end_pos * 255)) / 255 - 0.1
