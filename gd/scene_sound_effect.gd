extends AudioStreamPlayer


var success_sound = preload("res://sound/result/success.mp3")
var fail_sound = preload("res://sound/result/fail.mp3")
var kick_door_sound = preload("res://sound/result/kick door.mp3")


@onready var player = $"."


func play_sound(type):
	
	if type == null or type == "":
		return 
		
	var new_stream = null
	match type:
		"success_sound": new_stream = success_sound
		"fail_sound": new_stream = fail_sound
		"kick_door_sound": new_stream = kick_door_sound
	
	if new_stream:
		
		if player.stream == new_stream and player.playing:
			return
			
	player.stream = new_stream
	player.play()
	


func stop_sound():
	player.stop()
