extends AudioStreamPlayer


var ui_click = preload("res://sound/ui/ui_button_click.mp3")



@onready var player = $"."


func play_sound(type):
	
	if type == null or type == "":
		return 
		
	var new_stream = null
	match type:
		"ui_click": new_stream = ui_click
	
	if new_stream:
	
		if player.stream == new_stream and player.playing:
			return
			
	player.stream = new_stream
	player.play()





func stop_sound():
	player.stop()
