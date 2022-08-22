extends Node2D

onready var main_menu = preload("res://UI/MainMenu.tscn")
onready var level1 = preload("res://Levels/Level1.tscn")
onready var level2 = preload("res://Levels/Level2.tscn")
onready var level3 = preload("res://Levels/Level3.tscn")
onready var level4 = preload("res://Levels/Level4.tscn")
onready var level5 = preload("res://Levels/Level5.tscn")
onready var levels = [level1, level2, level3, level4, level5]

var high_scores = [0, 0, 0, 0, 0]

# Called when the node enters the scene tree for the first time.
func _ready():
	load_scores()
	main_menu()


func load_scores():
	var save_game = File.new()
#	high_scores = []
	save_game.open("user://save.sav", File.READ)
	if not save_game.file_exists("user://save.sav"):
		var high_scores = [0, 0, 0, 0, 0]
		return
		
	for i in range(0, 5):
		high_scores.append(int(save_game.get_line()))
		
	save_game.close()

func save_scores():
	var save_game = File.new()
	save_game.open("user://save.sav", File.WRITE)
	for i in high_scores:
		save_game.store_line(str(i))
	save_game.close()

func update_high_score(level, score):
	$Heartbeat.stop()
	level = level - 1
	if int(score) > high_scores[level]:
		high_scores[level] = int(score)
	
	var scores = ""
	for score in high_scores:
		scores += " " + str(score)
	$Label.text = scores
	
	save_scores()


func main_menu():
	$BGM.stop()
	for node in get_children():
		if not node.has_method("play"):
			node.queue_free()
	var menu = main_menu.instance()
	menu.connect("start_level", self, "start_level")

	add_child(menu)
	
	var counter = 0
	for score in menu.get_node("HighScores").get_children():
		score.text = str(high_scores[counter])
		counter += 1

func start_level(level):
	$Menu.play()
	for node in get_children():
		if not node.has_method("play"):
			node.queue_free()
	level = levels[level - 1].instance()
	level.connect("start_level", self, "start_level")
	level.connect("main_menu", self, "main_menu")
	level.connect("update_high_score", self, "update_high_score")
	add_child(level)
	$BGM.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
