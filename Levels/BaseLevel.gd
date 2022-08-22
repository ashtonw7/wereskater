extends Node2D

export var level = 1
signal start_level
signal main_menu
signal update_high_score

# Called when the node enters the scene tree for the first time.
func _ready():
	$Player.connect("level_complete", self, "level_complete")
	$CanvasLayer.connect("main_menu", self, "main_menu")
	$CanvasLayer.connect("restart", self, "restart")

func level_complete(completed):
	$Dev_Tiles.queue_free()
	$Player.state = 0
	$Player.queue_free()
	$WerewolfMode.queue_free()
	$LevelEnd.queue_free()
	
	get_parent().get_node("BGM").stop()
	get_parent().get_node("Skate").stop()
	
	if completed:
		get_parent().get_node("Howl").play()
		$CanvasLayer.get_node("LevelComplete").text = "Level Complete!"
		$CanvasLayer.get_node("FinalScore").text = "Score: " + str($CanvasLayer.get_node("Score").get_node("Score").text)
		emit_signal("update_high_score", level, $CanvasLayer.get_node("Score").get_node("Score").text)
	else:
		get_parent().get_node("Howl").stop()
		$CanvasLayer/Score/Score.text = "0"
		get_parent().get_node("Scratch").play()
		$CanvasLayer.get_node("LevelComplete").text = "WIPEOUT!"
		
	$CanvasLayer.get_node("Score").queue_free()
	$CanvasLayer.get_node("LevelComplete").visible = true
	
	if completed:
		$CanvasLayer.get_node("FinalScore").visible = true
	$CanvasLayer.get_node("Restart").visible = true
	$CanvasLayer.get_node("Menu").visible = true




func restart():
	emit_signal("start_level", level)

func main_menu():
	get_parent().get_node("Menu").play()
	emit_signal("main_menu")
